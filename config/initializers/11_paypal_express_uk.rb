########################################################################
# File::    11_paypal_express_uk.rb
# (C)::     Hipposoft 2011
#
# Purpose:: A very thin UK specific veneer over the PayPal Express
#           Checkout mechanism supported by ActiveMerchant.
#
#           The class herein is a simple subclass of the generic
#           PaypalExpressGateway for express checkouts with a UK variant
#           that is instantiated and used in exactly the same way.
#
#           For more information, see "config/payment_gateway.yml".
# ----------------------------------------------------------------------
#           05-Mar-2011 (ADH): Imported from Artisan.
########################################################################

class PaypalExpressUkGateway < ActiveMerchant::Billing::PaypalExpressGateway
  self.default_currency    = 'GBP'
  self.supported_countries = [ 'GB' ]
  self.display_name        = 'PayPal Express Checkout (UK)'
end
