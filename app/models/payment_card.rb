########################################################################
# File::    payment_card.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Support a payment (credit/debit) card entry form with
#           ActiveRecord-like validations but without needing a database
#           table underneath.
# ----------------------------------------------------------------------
#           23-Mar-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

class PaymentCard < WithoutTable

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  # This model has no database representation - see "models/without_table.rb".

  self.abstract_class = true # Keeps AR quiet but does not prevent instantiation

  # Card details

  column :card_name,   :string
  column :card_type,   :string
  column :card_number, :string
  column :card_cvv,    :string
  column :card_to,     :datetime
  column :card_from,   :datetime
  column :card_issue,  :string

  validates_presence_of :card_name,
                        :card_type,
                        :card_number

  validate              :not_expired,
                        :valid_number,
                        :valid_type,
                        :valid_switch_or_solo_attributes,
                        :valid_cvv_if_needed

  def not_expired
    errors.add( :card_to, :has_expired ) if card.expired?
  end

  def valid_number
    # Don't add both "cannot be blank" and "is invalid" errors to the same field
    errors.add( :card_number, :is_invalid ) unless card_number.blank? || ActiveMerchant::Billing::CreditCard.valid_number?( card_number )
  end

  def valid_type
    # Views should use a menu of type options, but this is here in case someone
    # tries to try and hack the site with a custom form request
    errors.add( :card_type, :is_invalid ) unless card_type.blank? || ActiveMerchant::Billing::CreditCard.card_companies.keys.include?( card_type )
  end

  def valid_switch_or_solo_attributes
    if ( %w{ switch solo }.include?( card_type ) )
      errors.add( :card_issue, :is_invalid ) unless card.valid_issue_number( card_number ) # Very odd API!
    end
  end

  def valid_cvv_if_needed
    if ( ActiveMerchant::Billing::CreditCard.requires_verification_value? )
      errors.add_on_blank :card_cvv
    end
  end

  # Overwrite the card number writer method to strip spaces from the
  # value given (ActiveMerchant does not like spaces in card numbers).
  
  def card_number=( value )
    write_attribute( :card_number, value.gsub( ' ', '' ) )
  end

  # User billing address details

  column :address_1,   :string
  column :address_2,   :string
  column :address_3,   :string
  column :city,        :string
  column :state,       :string
  column :country,     :string
  column :postcode,    :string

  validates_presence_of :address_1,
                        :city,
                        :country

  # Limitations

  MAXLEN_ADDRESS_1   = 256
  MAXLEN_ADDRESS_2   = 256
  MAXLEN_ADDRESS_3   = 256
  MAXLEN_CITY        = 128
  MAXLEN_STATE       = 128
  MAXLEN_COUNTRY     = 128
  MAXLEN_POSTCODE    = 64

  MAXLEN_CARD_NUMBER = 20
  MAXLEN_CARD_CVV    = 4
  MAXLEN_CARD_ISSUE  = 20

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # N/A

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Read-only accessor style method which defines a credit card with Active
  # Merchant and caches the result internally. Only read the card once you
  # have filled in the various "card_..." column values (see above).
  #
  def card
    names      = card_name.try( :split, ' ' ) || []
    first_name = names.shift
    last_name  = names.join( ' ' )

    @card ||= ActiveMerchant::Billing::CreditCard.new(
      :first_name         => first_name,
      :last_name          => last_name,

      :number             => card_number,
      :type               => card_type,
      :month              => card_to.try( :month ).to_s,
      :year               => card_to.try( :year  ).to_s,

      :verification_value => card_cvv,

      :start_month        => card_from.try( :month ).to_s,
      :start_year         => card_from.try( :year  ).to_s,
      :issue_number       => card_issue
    )
  end
end
