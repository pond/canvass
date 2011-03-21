########################################################################
# File::    payment_gateway_offsite_controller.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Handle order payment via off-site payment gateways such as
#           PayPal express checkout. Uses ActiveMerchant to partially
#           abstract away from the actual payment method in use, but
#           assumes PayPal style redirection semantics:
#
#           - Set up gateway passing an on-success and on-failure URL
#           - Data returned gives the off-site location to use
#           - Redirect there and wait for on-success or on-failure URL
#             to be visited
#           - If successful, acquire payment summary details from
#             remote service, present to user and ask for final order
#             confirmation
#           - If user confirms, finalise order and make the payment.
#
#           Currently this code uses the PayPal Express Checkout system.
#           The ActiveMerchant API is a little unhelpful, having rather
#           specific interfaces for express checkout (e.g. things like
#           "gateway.express.purchase", rather than, say, a more generic
#           "gateway.offsite.purchase", or something). You may need to
#           make significant code changes to switch to another off-site
#           provider as a result.
#
#           The controller is RESTful though the mapping is a bit
#           strained:
#
#           GET new: Kick off the express payment process and redirect
#                    to the offsite gateway (kind of "auto-create")
#
#           GET delete: Cancel process at any stage.
#
#           GET edit: The offsite gateway comes here if successful. In
#                     theory the user could edit aspects of their
#                     payment before confirmation (e.g. add gift wrap)
#                     though we don't support that here.
#
#           PUT update: The edit form above (fake-)PUTs here to make the
#                       final payment.
#
#                       MONEY IS PAID HERE and here only.
# ----------------------------------------------------------------------
#           11-Mar-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

class PaymentGatewayOffsiteController < PaymentGatewayController

  # NB: Security and other filters - see the superclass.

  def delete; super; end

  # Start a new payment session.
  #
  def new

    if ( ! PaymentGateway.instance.gateway_is_express_only() &&
         ! PaymentGateway.instance.gateway_has_express_support() )
      raise "Off-site checkout is impossible without an Express-capable gateway"
    end

    # Talk to the payment gateway.

    gateway_response = express_gateway().setup_purchase(

      @donation.amount_for_gateway(),
      :currency          => @donation.currency.code,

      :ip                => request.remote_ip,
      :order_id          => @donation.id.to_s, # Do not change; see "valid_donation_found"
      :description       => @donation.poll_title,
      :return_url        =>   edit_poll_payment_gateway_offsite_url( :poll_id => @donation.poll_id ),
      :cancel_return_url => delete_poll_payment_gateway_offsite_url( :poll_id => @donation.poll_id )
    )

    if gateway_response.success?
      redirect_to( express_gateway().redirect_url_for( gateway_response.token ) )
    else
      flash[ :error ] = t(
        :'uk.org.pond.canvass.controllers.payment_gateway_offsite.error_paypal',
        :message => gateway_response.message.chomp( '.' )
      )

      redirect_to( root_path() )
    end
  end

  # Once the user has dealt with the offsite payment gateway they're directed
  # back here. This lets them "edit" the final details of their order and
  # submit it via a form which POSTs to the "create" action.
  #
  def edit
    redirect_to( root_path() ) and return unless ( params[ :token ] )

    # Get the gateway response and find the expected purchase details based on
    # current user and required state.

    begin
      gateway_response = express_gateway().details_for( params[ :token ] )
      raise gateway_response.message unless gateway_response.success?
    rescue => error
      appctrl_report_error( error )
      redirect_to( root_path() )
      return
    end

    @address = gateway_response.address if ensure_donation_is_valid_and_set_variables( gateway_response ) # Else redirection has happened within the called validity checking method
  end

  # Make a payment and finalise an order. See the "edit" action for details.
  #
  def update

    # It's nice to check to see if the poll was closed or deleted *before* we
    # go into the payment loop and give a nasty 'red error' due to the Donation
    # object raising errors about it later.

    poll  = Poll.find_by_id( @donation.poll_id )
    token = nil

    if ( poll.nil? == true )
      token = :'activerecord.errors.models.donation.poll_has_vanished'
    elsif ( poll.workflow_state.to_sym != Poll::STATE_OPEN )
      token = :'activerecord.errors.models.donation.poll_is_not_open'
    end

    unless ( token.nil? )
      Donation.safely_destroy_initial_state_donations_for( current_user )
      flash[ :attention ] = I18n.t( token )
      redirect_to( root_path() )
      return
    end

    # The poll looks OK at this instant, so start paying. If the poll manages
    # to get deleted or closed during the processing of the code below via a
    # different request thread, tough luck; the user gets a nasty looking error
    # message, but at least nothing breaks.

    @payment_made = false

    status = begin
      Donation.transaction do

        # Store basic information and action the payment on our side before
        # talking to the database. If there's a basic failure, e.g. the poll
        # is not open yet, then an exception will be raised and we'll roll
        # back these changes *before* having paid.

        @donation.notes          = params[ :notes ] || ''
        @donation.invoice_number = InvoiceNumber.next!

        @donation.paid! # See Workflow state machine definitions in donation.rb
        @donation.save!

        # Now talk to the gateway.

        @gateway_response = express_gateway().purchase(

          @donation.amount_for_gateway(),
          :currency => @donation.currency.code,

          :ip       => request.remote_ip,
          :payer_id => params[ :payer_id ],
          :token    => params[ :token    ]
        )

        # Remember, ActiveRecord's transaction handler catches this exception
        # so the outer block will exit without the 'rescue' clause activating
        # and will evaluate to 'nil'.

        raise ActiveRecord::Rollback unless @gateway_response.success?

        # OK, we've paid... This instance variable is purely used to modify the
        # message shown to the user if something goes wrong.

        @payment_made = true

        # Store payment details. We can't do this before talking to the
        # gateway as it tells us information we must record, so we're forced
        # to risk a possible failure below *after* having paid.
        #
        # Only 'authorization' is strictly needed for refunds, but the other
        # two fields, used to make the payment, are recorded in case of some
        # kind of future dispute requires deeper investigation.

        @donation.authorisation_tokens             = {}
        @donation.authorisation_tokens[ :offsite ] = {}
        @donation.authorisation_tokens[ :offsite ][ :payer_id      ] = @gateway_response.payer_id()
        @donation.authorisation_tokens[ :offsite ][ :token         ] = @gateway_response.token()
        @donation.authorisation_tokens[ :offsite ][ :authorization ] = @gateway_response.authorization()
        @donation.save! # Yes, again...

        true # Inner transaction block evaluates to true => success.
      end

      # Outer block evaluates to result from inner transaction block.

    rescue => error
      error.message # Outer block evaluates to String => error message.

    end

    # Status:
    #
    # nil    -> Gateway call failure; check "@gateway_response.message".
    # String -> Exception; string gives message. The user might have been
    #           charged, but our local database operations failed.
    # true   -> Success.
    #
    if ( status != true )

      if ( @payment_made == true )
        flash[ :error ] = t(
          :'uk.org.pond.canvass.controllers.payment_gateway_offsite.error_failed_but_maybe_charged',
          :admin   => ActionView::Base.new.mail_to( ADMINISTRATOR_EMAIL_ADDRESS ), # config/initializers/50_general_settings.rb
          :message => status.chomp( '.' )
        )
      else
        flash[ :error ] = t(
          :'uk.org.pond.canvass.controllers.payment_gateway_offsite.error_failed_but_not_charged',
          :message => status.chomp( '.' )
        )
      end

      redirect_to( root_path() )

    else

      # See the Donation model for comments on why this is done here - this line
      # of code causes all related notification e-mail messages to be sent.

      @donation.send_new_item_notifications()

      appctrl_set_flash( :notice )
      redirect_to( user_donation_path( :id => @donation.id, :user_id => @donation.user_id ) )

    end
  end

private

  # Return an express gateway object.
  #
  def express_gateway
    if ( PaymentGateway.instance.gateway_is_express_only() )
      return gateway() # See superclass
    else
      return gateway().express
    end
  end
end
