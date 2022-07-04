class Paypal::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :paypal_init

  # TODO: Documentation.
  #
  def request_payment
    poll_id  = params[ :poll_id         ]
    integer  = params[ :amount_integer  ].to_i
    fraction = params[ :amount_fraction ].to_i
    money    = Money.from_cents( integer * 100 + fraction, 'GBP' )
    request  = PayPalCheckoutSdk::Orders::OrdersCreateRequest.new

    request.request_body(
      {
        intent:         'CAPTURE',
        purchase_units: [
          {
            amount: {
              currency_code: 'GBP',
              value:         money.to_s
            }
          }
        ]
      }
    )

    response = @client.execute( request )
    token    = response.result.id
    donation = Donation.generate_for(
      Poll.find( poll_id ),
      current_user,
      integer,
      fraction
    )

    donation.authorisation_tokens = token
    donation.save!

    render( json: { token: token }, status: :ok )

  rescue PayPalHttp::HttpError # No human-readable messages
    flash[:error] = I18n.t('uk.org.pond.canvass.controllers.payments.error_from_paypal_api')
    render( json: {}, status: 500 )
  rescue => exception
    appctrl_report_error( exception.message )
    render( json: {}, status: 500 )
  end

  # TODO: Documentation.
  #
  def confirm_payment
    donation = Donation.find_by!(
      user_id:              current_user.id,
      workflow_state:       Donation::STATE_INITIAL.to_s,
      authorisation_tokens: params[ :token ]
    )

    request  = PayPalCheckoutSdk::Orders::OrdersCaptureRequest.new( params[ :token ] )
    response = @client.execute( request )

    if response.result.status == 'COMPLETED'
      Donation.transaction do
        donation.invoice_number = InvoiceNumber.next!
        donation.paid! # See Workflow state machine definitions in donation.rb
        donation.save!
      end

      appctrl_set_flash( :notice )
      render( json: { status: response.result.status }, status: :ok )
    else
      raise PayPalHttp::HttpError.new(500, {}, {})
    end

  rescue PayPalHttp::HttpError # No human-readable messages
    flash[:error] = I18n.t('uk.org.pond.canvass.controllers.payments.error_from_paypal_api')
    render( json: {}, status: 500 )
  rescue => exception
    appctrl_report_error( exception.message )
    render( json: {}, status: 500 )
  end

  # ===========================================================================
  # PRIVATE INSTANCE METHODS
  # ===========================================================================
  #
  private

    # Call as a before_action. Sets @client to a PayPal SDK client instance.
    #
    def paypal_init
      environment = PayPal::SandboxEnvironment.new(
        PAYPAL_CLIENT_ID,
        PAYPAL_CLIENT_SECRET
      )

      @client = PayPal::PayPalHttpClient.new( environment )
    end


end
