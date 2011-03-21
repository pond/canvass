########################################################################
# File::    payment_gateway_onsite_controller.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Handle order payment via on-site payment using external
#           (but invisible to the user) web services for actual card
#           verification and payments or refunds. Uses ActiveMerchant
#           to abstract away from the actual payment method in use, but
#           currently tested for PayPal Payflow Pro (AKA Website
#           Payments Pro in the UK, but not in the US, where WPP is an
#           entirely different thing).
#
#           The code has been tested with PayPal direct payments, though
#           provided the gateway supports 'authorize' and 'capture' for
#           purchase, 'void' for cancellation and 'credit' for refunds it
#           ought to work with this controller without modification.
#
#           The controller is almost RESTful:
#
#           GET new: Enter card details, submit form for 'create'.
#
#           PUT create: Check card details and if OK render 'edit'. We render
#                       rather than redirect as additional temporary data from
#                       the form submission is needed in the new. 'Edit' shows
#                       the order confirmation page (very similar to that used
#                       for the offsite payment process).
#
#           POST update: The edit form above POSTs here to make the
#                        final payment.
#
#                        MONEY IS PAID HERE and here only.
#
#           GET delete: Cancel process at any stage.
# ----------------------------------------------------------------------
#           11-Mar-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

class PaymentGatewayOnsiteController < PaymentGatewayController

  # NB: Security and other filters - see the superclass.

  def delete; super; end

  # The main heading is skipped for action "create" as the desire to avoid
  # storing card details anywhere permanent leads to an odd non-RESTful
  # flow within the application. Since the form for "new" may be re-rendered
  # if "create" encounters an error (e.g. validations), then if we skip the
  # heading on the one action, we must skip it in the other too and deal
  # with the repercussions in the view.
  #
  #   new     -> enter card details and submit to 'create'
  #   create  -> check card details and if OK render 'edit' view so that
  #              the form submission state data from 'new' can be carried
  #              into the 'edit' form too; except 'edit' now renders from
  #              the 'create' action, so would get the wrong main heading
  #              by default. Since we only ever render 'edit' from 'create'
  #              upon success, there will be a flash message which will do
  #              instead.
  #   update  -> Accept the 'edit' form (rendered from 'create', see above)
  #              and (try to) pay for and confirm the order.
  #   delete  -> Delete the temporary donation data via the superclass.
  #
  def skip_main_heading?
    action_name == 'new' || action_name == 'create'
  end

  # Start a new payment session.
  #
  def new

    if ( PaymentGateway.instance.gateway_is_express_only() )
      raise "On-site checkout is impossible with an Express-only gateway"
    end

    # Use the current user's non-unique (i.e. theoretically "normal") user name
    # (rather than the Hub augmented unique name) as the card name initially.
    # The user can edit this if they want.

    @item           = PaymentCard.new
    @item.card_name = hubssolib_get_user_name

  end

  # Take the payment details form and turn this into a PaymentCard instance.
  # Handle errors with this, or if OK, reserve the order amount via the card
  # and the payment gateway. Again, handle errors, or if OK, render the 'edit'
  # view so the user can confirm their donation.
  #
  def create
    @item = PaymentCard.new( params[ :payment_card ] )
    if ( @item.valid? )

      begin

        gateway_response = gateway.authorize(
          @donation.amount_for_gateway(),
          @item.card,
          :currency => @donation.currency.code
        )

        raise gateway_response.message unless ( gateway_response.success? )
        @donation.authorisation_tokens = gateway_response.authorization

        # Save the updated donation object and set things up so that the 'edit'
        # view can be rendered - this matches up with the offsite payment
        # gateway behaviour and presents the user with their final chance to
        # cancel or confirm the order. The result will come in as a call to the
        # 'update' action.

        @donation.save!

        @notes       = ''
        @address     = {
          'name'     => @item.card_name,
          'address1' => @item.address_1,
          'address2' => @item.address_2,
          'address3' => @item.address_3,
          'city'     => @item.city,
          'state'    => @item.state,
          'zip'      => @item.postcode,
          'country'  => @item.country
        }

        # Leave the 'render' call out of the block. It shouldn't fail during
        # production runs unless there's a bug in the code. If inside the
        # exception handler, this results in a double render error when the
        # redirection call below is made, obscuring the real problem.

      rescue => error
        appctrl_report_error( error )
        redirect_to( root_path() )
        return

      end

      # Note early exit cases above - we only get here if everything worked.

      render( { :action => :edit } )

    else # @item not valid -> re-render 'new' form to show the user the errors
      render( { :action => :new } )

    end
  end

  # The user wants to confirm their order.
  #
  def update
    begin
      Donation.transaction do

        @donation.notes          = params[ :notes ] || ''
        @donation.invoice_number = InvoiceNumber.next!

        transaction_token_record            = {}
        transaction_token_record[ :onsite ] = {}

        gateway_response = gateway.capture(
          @donation.amount_for_gateway(),
          @donation.authorisation_tokens,

          :currency => @donation.currency.code,
          :ip       => request.remote_ip
        )

        raise gateway_response.message unless ( gateway_response.success? )

        @donation.authorisation_tokens            = {}
        @donation.authorisation_tokens[ :onsite ] = gateway_response.authorization
        @donation.paid!
        @donation.save!
      end

      # Success!
      #
      # See the Donation model for comments on why this is done here - this line
      # of code causes all related notification e-mail messages to be sent.

      @donation.send_new_item_notifications()

      appctrl_set_flash( :notice )
      redirect_to( user_donation_path( :id => @donation.id, :user_id => @donation.user_id ) )

    rescue => error

      # Report errors and hope the user can do something about it if need be!

      appctrl_report_error( error )
      redirect_to( root_path() )
    end
  end
end
