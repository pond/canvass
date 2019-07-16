########################################################################
# File::    51_load_payment_settings.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Load the payment settings from "config/payment_gateway.yml"
#           and define various constants on the basis of its contents.
# ----------------------------------------------------------------------
#           06-Mar-2011 (ADH): Imported from Artisan.
########################################################################

settings = YAML::load_file( File.join( Rails.root, 'config', 'payment_gateway.yml' ) )
settings = settings[ Rails.env ]

# Support 'real' ActiveMerchant gateway classes as well as any we might have
# defined within Artisan.

begin
  PAYMENT_CLASS = "ActiveMerchant::Billing::#{ settings[ 'gateway' ] }".constantize
rescue
  PAYMENT_CLASS = settings[ 'gateway' ].constantize
end

PAYMENT_LOGIN     = settings[ 'login'     ]
PAYMENT_PASSWORD  = settings[ 'password'  ]
PAYMENT_SIGNATURE = settings[ 'signature' ]
