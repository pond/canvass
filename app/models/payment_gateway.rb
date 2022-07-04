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
