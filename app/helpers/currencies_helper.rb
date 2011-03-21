########################################################################
# File::    currencies_helper.rb
# (C)::     Hipposoft 2009, 2010, 2011
#
# Purpose:: Utility methods for currency-related views.
# ----------------------------------------------------------------------
#           08-Mar-2009 (ADH): Created.
#           18-Feb-2011 (ADH): Imported from Artisan.
########################################################################

module CurrenciesHelper

  # As currencyhelp_print below, but composes an integer part and a fraction
  # part, expressed as strings, into one price. Non-numeric characters in
  # either part are stripped (though, in addition to the currency symbol,
  # non-numeric characters might appear in the output because they're present
  # in the formatting template for the given currency).
  #
  # The final optional parameter is passed through to currencyhelp_print -
  # see there for details.
  #
  # See also: currencyhelp_print()
  #
  def currencyhelp_compose( currency, integer, fraction, converter = false )
    return currencyhelp_print(
             currency,
             Currency.simplify( integer, fraction ),
             converter
           )
  end

  # Use the given currency's settings to print a fully formatted monetary
  # value passed in as a string containing a floating point value, or a type
  # which can convert to a string with "to_s" and give a floating point style
  # result (e.g. a BigDecimal or an actual Float).
  #
  # If the optional "converter" parameter is set to 'true', then HTML which
  # pops up a currency conversion hint via Google will be included, but only
  # if there's a currently logged in user (so the target currency is known)
  # and only if the currency requested differs from the target.
  #
  # See also: currencyhelp_compose()
  #
  def currencyhelp_print( currency, value, converter = false )
    rounding = Currency::ROUNDING_ALGORITHMS[ currency.rounding_algorithm ] ||
               Currency::ROUNDING_ALGORITHMS[ Currency::DEFAULT_ROUNDING_ALGORITHM ]
    numeric  = rounding[ :proc ].call( currency, value.to_s )
    decimal  = numeric.index( '.' )

    # Split up the number, which is stored as a string in mathematical
    # "integer-dot-fraction" notation.

    if ( decimal.nil? )
      fraction = ''
      integer  = numeric
    else
      fraction = numeric[ ( decimal + 1 )..-1 ]
      integer  = numeric[ 0..( decimal - 1 )  ]
    end

    # Use the template formatter to process these.

    formatted_integer = currencyhelp_format(
      ( currency.integer_template || '' ).reverse,
      integer
    )

    formatted_fraction = currencyhelp_format(
      ( currency.fraction_template || '' ),
      fraction
    )

    formatted_value  = formatted_integer
    formatted_value += currency.delimiter + formatted_fraction unless ( formatted_fraction.empty? )

    # Canvass doesn't use Locations like Artisan.
    #
    # # Build a currency converter link?
    # 
    # if ( converter                             &&
    #      logged_in?                            &&
    #      ! current_user.location.nil?          &&
    #      ! current_user.location.currency.nil? &&
    #      current_user.location.currency_id != currency.id )
    # 
    #   converter_link = " " + link_to(
    #     image_tag(
    #       'famfamfam_silk_icons/currency.png',
    #       :size  => '16x16',
    #       :alt   => '£',
    #       :align => 'top',
    #       :class => 'currency_converter'
    #     ),
    #     "http://www.google.com/search?q=convert+#{ formatted_value }+#{ currency.code }+to+#{ current_user.location.currency.code }",
    #     :target => '_blank',
    #     :class  => 'help'
    #   )
    # 
    # end # (Else converter_link ends up 'nil' by default)
    converter_link = nil

    # Compile the result

    if ( currency.show_after_number )
      return "#{ formatted_value }#{ currency.symbol }#{ converter_link }" 
    else
      return "#{ currency.symbol }#{ formatted_value }#{ converter_link }" 
    end
  end

  # For a given user or currency object, return form fields for the given form
  # object (that is, the "f" in view code such as "form for <foo> do |f|...")
  # which let someone input a price for a given named field in either the given
  # currency or a currency appropriate to the given user's configured location.
  #
  # The optional fourth parameter is used if the text input field generator
  # methods are not going to be able to determine the initial value (if any)
  # to use, perhaps because the fields are being generated for a non-
  # ActiveRecord object, such as a simple hash. Provide this object (e.g. a
  # hash) in the fourth parameter; the field names used ("<name>_integer" and
  # "<name>_fraction") are looked up in this object with the "[]" operator to
  # obtain the value.
  #
  # Text fields are generated for the given name with "_integer" or "_fraction"
  # appended, for the integer and fractional parts respectively.
  #
  def currencyhelp_edit( user_or_currency, form, name, data_source = nil )
    currency = ( user_or_currency.is_a?( User ) ) ? Currency.get_best_currency( user_or_currency ) : user_or_currency
    result   = ''

    # TODO: This is for the variable "column names" (attribute names) in the
    # currency editor row(s) for advanced artwork search originally. The search
    # model's "price" column is a serialized hash of the price data. The form
    # calling to this method uses proper nested attributes format, but even if
    # the hash is converted to an OpenStruct, the contents are ignored (noting
    # that "form.object" is always "nil" herein). The solution of passing in a
    # parameter as presently implemented is a nasty hack just to avoid wasting
    # a lot of time on a cleaner mechanism - hence "to do" later, if ever!

    extra           = {}
    field           = "#{ name }_integer"
    value           = data_source[ field ] unless ( data_source.nil? )
    extra[ :value ] = value || "0"

    result << currency.symbol unless ( currency.show_after_number )
    result << form.text_field(
                field.to_sym,
                {
                  :size      => 5, # 5 digits - that's a costly item!
                  :maxlength => Currency::MAXLEN_INTEGER_TEMPLATE
                }.merge( extra )
              )

    if ( currency.decimal_precision > 0 )
      extra           = {}
      field           = "#{ name }_fraction"
      value           = data_source[ field ] unless ( data_source.nil? )
      extra[ :value ] = value || "0" * ( currency.fraction_template.length )

      result << ( currency.delimiter || '' )
      result << form.text_field(
                  field.to_sym,
                  {
                    :size      => currency.decimal_precision,
                    :maxlength => currency.decimal_precision
                  }.merge( extra )
                )
    end

    result << currency.symbol if ( currency.show_after_number )
    return result
  end

  # Given an internal rounding algorithm name, return a human-readable
  # equivalent including hint string if available. Returned value is *not*
  # escaped with "h".
  #
  def currencyhelp_rounding_algorithm( algorithm )
    details   = Currency::ROUNDING_ALGORITHMS[ algorithm ]
    humanized = algorithm.humanize

    if ( details.nil? )
      humanized
    else
      "#{ humanized } (#{ details[ :hint ] })"
    end
  end

  # Return the result of 'select_tag' for a list of all currencies (this may be
  # modified by internal sorting, to avoid creating unnecessary copies). Runs
  # via apphelp_menu in the back-end so see that for details; broadly, pass the
  # array of Currency objects you want to list and an options hash which will
  # contain ":form" for a form_for based menu or nothing/":selected" for a
  # stand-alone menu (in which case, "params[ :currency_id ]" will be set when
  # the surrounding form is submitted).
  #
  def currencyhelp_menu( currencies, options = {} )
    Currency.apply_default_sort_order( currencies )
    values = currencies.collect { | c | [ "#{ h c.name }", c.id ] }

    return apphelp_menu( values, :currency_id, options )
  end

  # As "currencyhelp_menu" but builds a rounding algorithm selector menu
  # instead of a currency selector menu. Sets the "rounding_algorithm" field
  # of a form_for <some object> / sets params[ :rounding_algorithm ] for
  # stand-alone menus.
  #
  def currencyhelp_rounding_algorithm_menu( options = {} )
    algorithms = Currency::ROUNDING_ALGORITHMS
    values     = Currency::ROUNDING_ALGORITHM_ORDER.collect do | name |
      [ currencyhelp_rounding_algorithm( name ), name ]
    end

    return apphelp_menu( values, :rounding_algorithm, options )
  end

  # As "currencyhelp_menu" but provides a fixed preset list of decimal
  # precision choices.
  #
  def currencyhelp_decimal_precision_menu( options = {} )
    values     = []
    precisions = {
       '4' => '4: 1234.1234',
       '3' => '3: 1234.123',
       '2' => '2: 1234.12',
       '1' => '1: 1234.1',
       '0' => '0: 1234',
      '-1' => '-1: 1230',
      '-2' => '-2: 1200',
      '-3' => '-3: 1000'
    }

    sorted = precisions.keys.sort { | a, b | b.to_i <=> a.to_i }
    values = sorted.collect do | key |
      [ precisions[ key ], key.to_i ]
    end

    return apphelp_menu( values, :decimal_precision, options )
  end

private

  # Run through a template strings from left to right adding characters from
  # a given integer value (expressed as a string) if there's a numeric entry in
  # the template, else adding the template's non-numeric character at that
  # position. If there's anything left of the value string once the loop has
  # finished, add the remaining data to the front of the formatted result.
  #
  # Using per-byte processing means that multibyte characters drop out "in
  # the wash", since they'll all be added from the template before the next
  # numeric character (0-9 => single byte) gets encountered - bearing in mind
  # that this is a Rails application using UTF-8 encoding in Ruby via $KCODE.
  #
  # Can be used to process integer parts of floats-as-strings by passing in the
  # template as "template.reverse", or for the fraction parts by passing in the
  # template directly. See currencyhelp_print for example usage.
  #
  def currencyhelp_format( template, value )
    formatted = ''

    template.each_byte do | byte |
      break if ( value.empty? )

      byte      = '' << byte # Convert from character code to string
      add       = ( byte < '0' || byte > '9' ) ? byte : value.slice!( -1..-1 )
      formatted = "#{ add }#{ formatted }"
    end

    formatted = "#{ value }#{ formatted }" unless ( value.empty? )
    return formatted
  end
end
