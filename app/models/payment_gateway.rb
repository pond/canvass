########################################################################
# File::    payment_gateway.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Model class which holds some static information about some
#           payment gateway types. Not an ActiveRecord sub-class.
# ----------------------------------------------------------------------
#           06-Mar-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

class PaymentGateway

  include Singleton

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  # None (this is not an ActiveRecord sub-class).

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # N/A

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Return a payment gateway instance based on the "PAYMENT_*" constants -
  # see "config/environments/<environment_in_use>.rb".
  #
  def gateway
    @gateway ||= PAYMENT_CLASS.new(
      :login     => PAYMENT_LOGIN,
      :password  => PAYMENT_PASSWORD,
      :signature => PAYMENT_SIGNATURE # Ignored for some gateway types; see "config/payment_gateway.yml"
    )
  end

  # It this gateway recognised as only supporting express checkout? Returns
  # 'true' if so, else 'false'.
  #
  def gateway_is_express_only
    PAYMENT_CLASS            == ActiveMerchant::Billing::PaypalExpressGateway ||
    PAYMENT_CLASS.superclass == ActiveMerchant::Billing::PaypalExpressGateway
  end

  # Is this gateway recognised as supporting express checkout via
  # 'gateway.express'? Returns 'true' if so, else 'false'. Note that some
  # gateways *only* support express checkout and would return 'false' from this
  # method; see also 'gateway_is_express_only', which must be checked first.
  #
  def gateway_has_express_support
    gateway().respond_to?( :express )
  end

  # Static list of unique PayPal locales known at the time of writing. See:
  #
  #   https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_WPButtonIntegration#id089QD0O0TX4
  #
  # ...and search downwards for table 2. The locale list has been sorted and
  # reduced to unique entries.

  PAYPAL_LOCALES = [
    :de_DE,
    :en_AU,
    :en_GB,
    :en_US,
    :es_ES,
    :es_XC,
    :fr_FR,
    :fr_XC,
    :it_IT,
    :ja_JP,
    :nl_NL,
    :pl_PL,
    :zh_CN,
    :zh_XC
  ]

  # Bulk payment limit - for PayPal, via the front-end, this is 5000 at the
  # time of writing. We limit it to fewer because attempting 5000 summarised
  # payments in one go would be pretty crazy - the chance of error in marking
  # paid/unpaid items would be huge (unless the payment gateway happens to
  # support fully automatic mass payments). The value is inclusive (so zero
  # would permit no payments and be invalid; 1 would permit just one payment
  # at a time and be pretty pointless).

  BULK_PAYMENT_LIMIT = 500 # (sic.)

  # Return a PayPal check-out button URL with the best guess mapping between
  # the PAYPAL_LOCALES and the given user's preferred language.
  #
  def self.paypal_get_checkout_url( user )
    code = user.language.try( :code ) || 'en'
    code.gsub!( /\-/, '_' )

    # Special case - "en" == "en_US"; other simple variants like "fr" need to
    # become "fr_FR" to match PayPal locales.

    if ( code == "en" )
      code = "en_US"
    else
      code = code + "_" + code.upcase unless ( code.include?( "_" ) )
    end

    code = "en_US" unless PAYPAL_LOCALES.include?( code.to_sym )

    return "https://www.paypal.com/#{ code }/i/btn/btn_xpressCheckout.gif"
  end

  # Payment gateways may differ in the way that amounts are specified.
  # Some payment gateways, e.g. PayPal, insist on integer hundredths. This
  # class method takes a BigDecimal with currency-rounded integer and fraction
  # parts (e.g. 12 UK pounds and 23.6 pence rounds to 12 pounds 24p, so the
  # BigDecimal would be "12.24") and returns a value appropriate for the
  # payment gateway in use. If you change gateway, you may need to update this.
  # The return type may vary with gateway (for PayPal, it is a Fixnum).
  #
  # To achieve correct currency-specific rounding of the value passed on input,
  # see "Currency#round" along with related methods and data in the Currency
  # model.
  #
  # See also "PaymentGateway::get_amount_for_humans".
  #
  def self.get_amount_for_gateway( currency_rounded_value )

    # PayPal specific: It wants integer hundredths. We always call 'floor' to
    # round down any trailing fractional part.

    ( currency_rounded_value * BigDecimal.new( '100' ) ).floor.to_i
  end

  # The opposite of "get_amount_for_gateway"; takes the given gateway amount
  # and returns a BigDecimal which may be fractional, depending upon the way
  # that "get_amount_for_gateway" works. Note that the gateway value may have
  # had rounding applied, so while this function does the best it can, there
  # is no way to completely 'undo' any original applied rounding.
  #
  def self.get_amount_for_humans( gateway_value )
    BigDecimal.new( gateway_value.to_s ) / BigDecimal.new( '100' )
  end

end
