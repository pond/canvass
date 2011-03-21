########################################################################
# File::    currency.rb
# (C)::     Hipposoft 2009, 2010, 2011
#
# Purpose:: Record details of a currency including the fiscally correct
#           way to round its values (dependent upon a hard-coded choice
#           of named rounding algorithms coded herein).
# ----------------------------------------------------------------------
#           14-Apr-2009 (ADH): Created.
#           18-Feb-2011 (ADH): Imported from Artisan.
########################################################################

require 'bigdecimal'

class Currency < ActiveRecord::Base

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  has_many :polls
  has_many :donations

  # Limitations and requirements. See also the rounding algorithms section.

  MAXLEN_NAME               = 160 # "Native name (English name)"
  MAXLEN_CODE               = 3   # ISO 4217 => 3-letter codes

  MAXLEN_INTEGER_TEMPLATE   = 32  # Fairly arbitrary - allows big integers (e.g. for Yen)
  MAXLEN_DELIMITER          = 8   # Usually just 1; 8 is a bit arbitrary
  MAXLEN_FRACTION_TEMPLATE  = 16  # Fairly arbitrary - allows long fractions/non-numerics in fractions

  MAXLEN_SYMBOL             = 16  # Often just 1; 16 is a bit arbitrary

  validates_presence_of     :name
  validates_numericality_of :decimal_precision, :only_integer => true

  # Default values (should only be needed in the migrations, but available
  # centrally here just in case). See also the rounding algorithms section.
  #
  # Decimal precision refers to *internal* rounding before the currency
  # specific rounding algorithm is used. So for example, Swiss Francs would
  # use a precision of 4, because the rounding algorithm works on the last
  # two of four decimal digits. The currency-specific rounded result will
  # always have equal or lower decimal precision.

  DEFAULT_DECIMAL_PRECISION = 2
  DEFAULT_SHOW_AFTER_NUMBER = false

  # See Jason King's "good_sort" plugin:
  #
  #   http://github.com/JasonKing/good_sort/tree/master
  #
  # Must use "table_exists?", as good_sort needs to check the database but
  # this class may be examined by migrations before the table is created.

  sort_on :name, :code, :symbol, :rounding_algorithm if Currency.table_exists?

  # How many entries to list per index page? See the Will Paginate plugin:
  #
  #   http://wiki.github.com/mislav/will_paginate

  def self.per_page
    MAXIMUM_LIST_ITEMS_PER_PAGE
  end

  # Search columns for views rendering the "shared/_simple_search.html.erb"
  # view partial and using "appctrl_build_search_conditions" to handle queries.

  SEARCH_COLUMNS = %w{name code symbol rounding_algorithm}

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # Only administrators and agents can modify the currency list.
  #
  def self.can_modify?( user, ignored )
    user.try( :is_agent? )
  end

  # ===========================================================================
  # ROUNDING ALGORITHMS - all take strings in, return strings out; returned
  # strings are formatted according to current locale numeric formatting
  # conventions and to "decimal_precision" places (subject to the rounding
  # algorithm details; Argentinian rounding uses a precision of 3 but may
  # return values quoted only to 2 decimal places).
  #
  # IMPORTANT - Keys are matched against rounding algorithm strings in the
  # database. Maximum key string length is MAXLEN_ROUNDING_ALGORITHM,
  # defined further below. DEFAULT_ROUNDING_ALGORITHM gives the value to use
  # if all else fails.
  #
  # The order of appearance herein has no relevance. Since the constant defines
  # a hash, Ruby may choose to enumerate the key/value pairs in any order. Use
  # ROUNDING_ALGORITHM_ORDER to establish a default sort order.
  # ===========================================================================

  ROUNDING_ALGORITHM_ORDER = [

    'mathematical',        # 0
    'round_up',            # 1
    'round_down',          # 2
    'argentinian',         # 3
    'swiss'                # 4

  ]

  validates_inclusion_of :rounding_algorithm, :in => ROUNDING_ALGORITHM_ORDER

  ROUNDING_ALGORITHMS = {
    ROUNDING_ALGORITHM_ORDER[ 0 ] => {
      # Mathematical
      :hint => 'ax: x < 5 -> x=0, x > 4 -> a+1, x=0',
      :proc => Proc.new do | currency, string |
        currency.rounding_internal( string, :round )
      end
    },

    ROUNDING_ALGORITHM_ORDER[ 1 ] => {
      # Round up
      :hint => 'ax: x -> a+1, x=0',
      :proc => Proc.new do | currency, string |
        currency.rounding_internal( string, :floor )
      end
    },

    ROUNDING_ALGORITHM_ORDER[ 2 ] => {
      # Round down
      :hint => 'ax: x -> x=0',
      :proc => Proc.new do | currency, string |
        currency.rounding_internal( string, :ceil )
      end
    },

    ROUNDING_ALGORITHM_ORDER[ 3 ] => {
      # Argentinian
      :hint => '0.0ax: x < 3 -> x=0; 2 < x < 8 -> x=5; x > 7 -> a+1, x=0',
      :proc => Proc.new do | currency, string |
        currency.rounding_argentinian( string )
      end
    },

    ROUNDING_ALGORITHM_ORDER[ 4 ] => {
      # Swiss
      :hint => '0.axy: xy < 26 -> xy=00; 25 < x < 76 -> xy=50; xy > 75 -> a+1, xy=00',
      :proc => Proc.new do | currency, string |
        currency.rounding_swiss( string )
      end
    }
  }

  # Maximum length of an algorithm name - used e.g. by the "create currencies"
  # migration; default algorithm choice.

  MAXLEN_ROUNDING_ALGORITHM  = 32
  DEFAULT_ROUNDING_ALGORITHM = ROUNDING_ALGORITHM_ORDER[ 0 ]

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Apply a default sort to the given array of Currency objects. The array is
  # modified in place.
  #
  def self.apply_default_sort_order( array )
    array.sort! { | x, y | x.name <=> y.name }
  end

  # Canvass doesn't use Locations like Artisan.
  #
  # # For first-time database setup and tests - establish static associations
  # # between currencies and locations.
  # #
  # def self.establish_predefined_associations
  #   assoc = {
  #     'United Kingdom'           => 'GBP',
  #     'France'                   => 'EUR',
  #     'Germany'                  => 'EUR',
  #     'Switzerland'              => 'SFR',
  #     'Canada'                   => 'CAD',
  #     'Japan'                    => 'JPY',
  #     'United States of America' => 'USD'
  #   }
  # 
  #   assoc.each do | name, code |
  #     location = Location.find( :first, :conditions => [ 'LOWER(name) LIKE LOWER(?)', "%#{ name }%" ] )
  #     currency = Currency.find_by_code( code )
  # 
  #     if ( location && currency )
  #       location.currency = currency
  #       location.save!
  #     end
  #   end
  # end

  # Try to find the best currency to use by default for the given user. If the
  # user has no associated location or 'nil' is passed, always returns GBP -
  # for artwork searches etc., the default currency used in the absense of a
  # product's user's location needs to be fixed and known in advance.
  #
  def self.get_best_currency( user )
    # Canvass doesn't use Locations like Artisan.
    #
    # if ( user && user.location && user.location.currency )
    #   return user.location.currency
    # else
        return Currency.find_by_code( 'GBP' ) || Currency.first
    # end
  end

  # Given an integer and fraction string, return a single string with all
  # non-numeric characters removed and a "." separating the integer and
  # fraction parts (or with no "." if the fraction part is empty).
  #
  def self.simplify( integer, fraction )
    integer  = clean( integer  )
    fraction = clean( fraction )

    return ( fraction.empty? ) ? integer : "#{ integer }.#{ fraction }"
  end

  # Add two numbers, expressed in integers or strings describing the integer
  # and fraction components of each, returning the result in an array of two
  # strings, index 0 holding the integer part and index 1 holding the fraction
  # part. Both are always present (e.g. ["3", "0"] => "3.0" => integer 3).
  #
  def self.add( integer1, fraction1, integer2, fraction2 )
    big1  = BigDecimal.new( simplify( integer1, fraction1 ) )
    big2  = BigDecimal.new( simplify( integer2, fraction2 ) )

    return ( big1 + big2 ).to_s( 'F' ).split( '.' )
  end

  # As 'add', but subtracts the value indicated by the second pair of
  # parameters from the value indicated by the first pair of parameters.
  #
  def self.subtract( integer1, fraction1, integer2, fraction2 )
    big1  = BigDecimal.new( simplify( integer1, fraction1 ) )
    big2  = BigDecimal.new( simplify( integer2, fraction2 ) )

    return ( big1 - big2 ).to_s( 'F' ).split( '.' )
  end

  # Multiply a number, expressed in integers or strings describing its integer
  # and fraction components, by a multipler, expressed as an integer, float or
  # string equivalent (such that a conversion to BigDecimal will result in the
  # desired mathematical result). Returns the result in the same way as
  # "add()" above.
  #
  # If you already have the multiplier as a BigDecimal, pass it in that format
  # for better efficiency.
  #
  def self.multiply( integer, fraction, multiplier )
    number     = BigDecimal.new( simplify( integer, fraction ) )
    multiplier = BigDecimal.new( permissive_clean( multiplier ) ) unless ( multiplier.is_a?( BigDecimal ) )

    return ( number * multiplier ).to_s( 'F' ).split( '.' )
  end

  # As 'multiply', but divides by the given divider value returning a result
  # without rounding, within the limits of BigDecimal precision.
  #
  def self.divide( integer, fraction, divider )
    number  = BigDecimal.new( simplify( integer, fraction ) )
    divider = BigDecimal.new( permissive_clean( divider ) ) unless ( divider.is_a?( BigDecimal ) )

    return ( number / divider ).to_s( 'F' ).split( '.' )
  end

  # Given a string quantity in 'natural' units (e.g. for UK pounds, a
  # string representing a floating point number with integer pounds and
  # fraction pence), return a rounded amount as a string. Rounding is
  # done according to the currency instance's defined rounding algorithm.
  #
  def round( float_as_string )
    rounding = Currency::ROUNDING_ALGORITHMS[ self.rounding_algorithm ]
    return rounding[ :proc ].call( self, float_as_string )
  end

  # Call with a value string and method of :round, :floor or :ceil. Returns a
  # value appropriate for a rounding function using mathematical, round-down
  # or round-up semantics, respectively.
  #
  def rounding_internal( string, method )
    bd = BigDecimal.new( string )
    dp = self.decimal_precision

    return "%.0#{ dp }f" % bd.send( method, dp )
  end

  # Works on the third decimal place; < 3, round down; >= 3, < 8, make 5;
  # >= 8, round up. Thus the result may have a third decimal digit value of
  # zero or 5 (i.e. in effect there's a two or three decimal digit result).
  #
  # For valid rounding, decimal precision MUST BE 4. This ensures that
  # mathematical rounding (to four decimal digits) does not influence the
  # value of the third digit.
  #
  def rounding_argentinian( string )
    str      = rounding_internal( string, :round )
    last_one = str.split( '.' )[ 1 ][ 2..2 ]

    if ( last_one < '3' )
      str = str.chop # Just chop out 3rd decimal place
    elsif ( last_one < '8' )
      str = str.chop + '5' # Chop out 3rd decimal place and replace with '5'
    else
      str = str.chop.next # Chop 3rd decimal place and round up"
    end

    return Currency.trim_to_numeric( str )
  end

  # Similar to Argentinian rounding, but examines the last two digits to
  # always arrive at a 2 decimal place result. Values < 26 => round down,
  # values > 75 => round up, values in between round to '5'.
  #
  # Decimal precision constraints are the same as for Argentinian rounding.
  #
  def rounding_swiss( string )
    str      = rounding_internal( string, :round )
    last_two = str.split( '.' )[ 1 ][ 1..2 ]

    if ( last_two < '26' )
      str = str.chop.chop.chop + '0'
    elsif ( last_two < '76' )
      str = str.chop.chop.chop + '5'
    else
      str = str.chop.chop.chop.next + '0'
    end

    return Currency.trim_to_numeric( str )
  end

  # ===========================================================================
  # PRIVATE
  # ===========================================================================

private

  # Trim any characters outside the range "0-9" from the end of a string.
  # Assumes that numeric values contain these characters only.
  #
  def self.trim_to_numeric( string )
    string.sub( /[^0-9]+$/, '' )
  end

  # Remove any character which is not a digit, minus sign or dot from the
  # given string. Does nothing about repetitions or position, so if you want
  # to use the result as an integer or float, some degree of input sanity must
  # already be present.
  #
  def self.permissive_clean( string )
    return string.to_s.gsub( /[^0-9\-.]/, '' )
  end
  
  # Remove *all* characters that are not digits from the given string. Allow a
  # leading "-" for negative numbers, with optional white space before it, but
  # no other spurious preceding characters.
  #
  def self.clean( string )
    string   = string.gsub( /^(\s)*\-/, "-" )
    negative = ( string[ 0 ] == 45 )

    string.gsub!( /[^0-9]/, '' )
    string = "-" + string if ( negative )

    return string
  end
end
