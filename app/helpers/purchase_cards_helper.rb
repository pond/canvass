########################################################################
# File::    purchase_cards_helper.rb
# (C)::     Hipposoft 2010
#
# Purpose:: Utility methods for views related to credit/debit cards.
# ----------------------------------------------------------------------
#           23-Mar-2010 (ADH): Created.
########################################################################

module PurchaseCardsHelper

  # Return HTML for a selection menu for the given form and method (e.g.
  # a method of ":card_type" to work for a form generated for a model instance
  # with the instance having a compatible attribute named ":card_type"). The
  # menu maps Active Merchant card types to internationalised human-readable
  # strings. When submitted, a form containing the menu will have a field name
  # based on the method name you supplied and a field value from the list of
  # Active Mercant card types. Code accepting the form submission should check
  # to make sure the card type is a supported value in case someone hacks the
  # form and tries to submit some other card type for some reason.
  #
  # Internationalisation runs through "apphelp_view_hint" with the Controller
  # set to "PaymentGatewayOnsiteController" and token names of
  # "card_type_<name>". If a translation is missing, an attempt to create a
  # decent result is generated from the raw card name directly.
  #
  # A blank first value *is* included so that users are forced to make a valid
  # selection for 'new' objects.
  #
  # If you want to only accept a certain list of cards, pass an array of card
  # types in the optional third parameter. Any of those cards supported by
  # ActiveMerchant will be shown. Any not supported by ActiveMerchant will be
  # ignored. Any additional supported card types not in your list will also be
  # ignored.
  #
  def purchasecardshelp_type_menu( form, method, permitted_types = nil )
    types = ActiveMerchant::Billing::CreditCard.card_companies.keys

    unless ( permitted_types.nil? )
      types.reject! do | card_type |
        ! permitted_types.include?( card_type )
      end
    end

    form.select(
      method,
      types.collect { | card_type |
        type_name = apphelp_view_hint(
          "card_type_#{ card_type }",
          PaymentGatewayOnsiteController,
          :default => card_type.titleize
        )

        [ type_name, card_type ]
      }.sort { | a, b | a[ 0 ] <=> b[ 0 ] },
      :include_blank => true
    )
  end
end
