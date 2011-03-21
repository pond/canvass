########################################################################
# File::    payment_gateway_controller.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Manage external payment gateways to process order payments.
# ----------------------------------------------------------------------
#           17-Feb-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

class PaymentGatewayController < ApplicationController

  include ActiveMerchant::Billing

  before_filter :ensure_user_is_valid_and_find_donation
  before_filter :ensure_donation_is_valid_and_set_variables, :except => [ :edit, :delete ]

  # Cancel payment.
  #
  def delete
    flash[ :notice ] = t(
      :'uk.org.pond.canvass.controllers.payment_gateway_offsite.view_cancelled'
    )

    # Redirection to the cart items list should destroy the initial state
    # donation and associated objects anyway, but do it explicitly here just
    # to make absolutely sure.

    Donation.safely_destroy_initial_state_donations_for( current_user )
    redirect_to( root_path() )
  end

protected

  # Set @notes to notes-for-sellers based on the current logged in user,
  # donation found in filter "ensure_user_is_valid_and_find_donation" and, if
  # provided, an external gateway response which includes an invoice ID
  # containing the expected donation ID. Pass no parameters to rely on the
  # current user always (@notes will then be "nil").
  #
  # Returns 'true' if successful or 'false' on failure, in which case an
  # error message has been set in the Flash and redirection has been requested.
  #
  # Called by a before_filter for most actions, so only really needed to be
  # invoked directly if there's a gateway response to consider.
  #
  def ensure_donation_is_valid_and_set_variables( gateway_response = nil )
    @notes = nil

    # If the gateway gave us a response hash we can try to find a "special
    # note to the seller" field and also make sure that the invoice ID given
    # in the "new" method has been returned and matches our expected donation.
    # Again set the donation value to nil to indicate an error if necessary.

    if ( ! @donation.nil? && ! gateway_response.nil? && gateway_response.params.is_a?( Hash ) )
      @notes = gateway_response.params[ "note"       ]
      iid    = gateway_response.params[ "invoice_id" ]

      @donation = nil if ( ! iid.blank? && iid.to_i != @donation.id )
    end

    # Handle errors with early exit.

    if ( @donation.nil? )
      flash[ :error ] = t(
        :'uk.org.pond.canvass.controllers.payment_gateway_offsite.error_donation_details_wrong'
      )

      redirect_to( root_path() )
      return false
    end

    return true
  end

private

  # Call as a before_filter. Ensures that a user is logged in and sets
  # "@donation" to the user's initial state Donation object. If this is
  # "nil" afterwards, something went wrong; abort the process.
  #
  # This is used rather than a Hub permissions hash because we don't want to
  # be asked to, say, log in if not already; all of that should be set up
  # correctly already and if anything looks out of the ordinary, when it comes
  # to payment and orders it is safest to just give up and redirect back to
  # the root path (possibilities: User reloaded old page, auto-URL completion
  # when typing in address directed them to unexpected location, bogus history
  # choice, etc. etc.).
  #
  def ensure_user_is_valid_and_find_donation
    redirect_to( root_path() ) and return unless ( logged_in? )

    @donation = Donation.find(
      :all,
      :conditions => {
        :user_id        => current_user.id,
        :workflow_state => Donation::STATE_INITIAL.to_s
      }
    )

    # If we seem to get the wrong number of donations back - for a given user,
    # exactly 1 should be in initial state, no more, no less - then reset the
    # donation value to nil to indicate an error condition, else pick out the
    # single array item.

    @donation = ( @donation.size != 1 ) ? nil : @donation[ 0 ]
  end

  # Lazy-initialise and return a payment gateway instance based on the
  # "PAYMENT_*" constants.
  #
  # For "PAYMENT_*", see "config/environments/<environment_in_use>.rb".
  #
  def gateway
    @gateway ||= PaymentGateway.instance.gateway()
  end
end
