########################################################################
# File::    translation.rb
# (C)::     Hipposoft 2009, 2010, 2011
#
# Purpose:: Manage model-like aspects of translations, although this is
#           not an ActiveRecord sub-class as it has no representation
#           in the database.
# ----------------------------------------------------------------------
#           16-Feb-2011 (ADH): Imported from Artisan.
########################################################################

class Translation

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  # None (this is not an ActiveRecord sub-class).

  # ===========================================================================
  # TRANSLATION
  # ===========================================================================

  # If Model.respond_to?( :columns_for_translation ) then call with the name
  # of a column to get a locale-specific version returned (will be the same
  # name if the column name isn't translated, or will have a locale suffix).
  #
  def self.translated_column( model, name )
    if ( model.columns_for_translation.include?( name.to_s ) )
      model.column_name_localized( name.to_s )
    else
      name
    end
  end

  # Reverse of "translated_column". Slow! Do not call frequently.
  #
  def self.untranslated_column( model, name_with_locale )
    for name in model.columns_for_translation()
      names_with_locales = model.available_translatable_columns_of( name )
      return name if names_with_locales.include?( name_with_locale.to_s )
    end

    return name_with_locale
  end

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # Agents (and administrators too, since "is_agent?" returns "true" for both)
  # are allowed to modify translations.
  #
  def self.can_modify?( user, ignored )
    user.try( :is_agent? )
  end

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Given an RFC 4646 compliant language code return the best match of actually
  # available language code that we can find. You can pass the code as a string,
  # a symbol, or an array of strings and/or symbols (mixtures of both are OK).
  # If using an array, the codes are assumed to be given in preference order,
  # most preferred first. A single, valid, currently available locale code
  # (according to the Rails I18n module) is always returned, as a Ruby Symbol.
  #
  # See class function 'set_best_locale' if you want to actually apply this
  # code to use as the current locale.
  #
  #   http://www.ietf.org/rfc/rfc4646.txt
  #   http://www.w3.org/International/articles/language-tags/
  #   http://guides.rubyonrails.org/i18n.html
  #
  # The matching strategy of RFC 4647 indicates that more specific language
  # tag should not match a less specific one. "de" matches "de-CH", say, but
  # "de-CH" should not match "de". Meanwhile, "zh-Hant" matches "zh-Hant-TW",
  # but not, say, "zh-Hans" or "zh-TW". That is, the script seems to be more
  # important than the region; importance decreases from left to right.
  #
  #   http://www.ietf.org/rfc/rfc4647.txt
  #   http://www.w3.org/International/articles/bcp47/
  #
  # Artisan needs to run the matching algorithm backwards. It tries to find a
  # language that matches exactly then looks to more and more general solutions.
  # We make an intelligent guess at the best approach given the RFC guidance.
  #
  # * Note that all matches should be case insensitive.
  # * If we get an exact match, use it immediately.
  # * Use the Locale gem to parse the language tag using proper REGEXPs (see
  #   below for URLs related to the Locale gem).
  # * Reconstruct a tag using just the language, script and region. This strips
  #   out any other data which we might not have recognised.
  # * If we get a match of this, use it (implies variant(s) etc. not matched)
  # * Try getting rid of the region. Match? Use it.
  # * We're left with language and script. If the user has a matching language
  #   and region but in a different script, there's a strong chance they can't
  #   read it and dropping back to the default locale is preferable.
  #
  #   http://www.yotabanana.com/hiki/ruby-locale-rails.html
  #   http://rubyforge.org/projects/locale/
  #
  # When presented with an array of codes, the function first tries an exact
  # match for each code in preference order, then tries the above generalised
  # matching algortihm for each code. If all attempts to match fail, it returns
  # the default locale.
  #
  # When calling this function, give thought to the source of the code or codes
  # passed in. These may be derived from a relevant location or, for example,
  # from the HTTP accept-language header (see the http_accept_language plugin,
  # which is installed and available within Artisan).
  #
  #   http://github.com/iain/http_accept_language/tree/master
  #
  # Note that behaviour is undefined if the function is given an empty array,
  # string, or any other unspecified input type or value.
  #
  # Further reading:
  #
  #   http://www.iana.org/assignments/language-subtag-registry
  #   http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  #   http://en.wikipedia.org/wiki/List_of_official_languages
  #   http://en.wikipedia.org/wiki/List_of_countries_by_native_names
  #   http://blog.grayproductions.net/articles/understanding_m17n
  #
  def self.select_best_locale( code_or_codes )
    available_locales = I18n.available_locales() # All symbols, no strings
    default_locale    = I18n.default_locale()    # A symbol, not a string
    downcase_locales  = available_locales.map() { | l | l.to_s.downcase }

    # Coerce code_or_codes to a flat array and make all entries into strings.

    codes = [ code_or_codes ].flatten
    codes.map!() { | code | code.to_s }

    # Try for an *exact* match from the preference-ordered array of codes.
    # Since the matches must be case-insensitive but the returned code must
    # be of correct case to obtain the right language file, we can't just use
    # array intersection (the '&' operator) - instead, have to step through
    # each item slowly.

    for code in codes
      found_at = downcase_locales.index( code.to_s.downcase )
      return available_locales[ found_at ] unless found_at.nil?
    end

    # Define a small procedure which builds a locale tag using the given
    # language, script and region - the last two parameters may be 'nil'.
    # The string equivalent of this new tag is case-insensitive compared
    # to the available locales and if a match is found, the correct case
    # locale symbol will be returned. In any other condition, returns nil.

    match = lambda() do | language, script, region |
      common_tag = Locale::Tag::Common.new( language, script, region )

      unless common_tag.nil?
        found_at = downcase_locales.index( common_tag.to_rfc.to_s.downcase )

        unless found_at.nil?
          return available_locales[ found_at ]
        end
      end

      return nil
    end

    # Use the above block of code to try matches with tags simplified in the
    # various ways described by comments below.

    for code in codes
      tag = Locale::Tag::Rfc.parse( code )
      next if tag.nil?

      # Try with just the language, script and region (no variants, etc.).

      found = match.call( tag.language, tag.script, tag.region )
      return found unless found.nil?

      # Try without the region, but keep the script. Must not remove this
      # because in some languages even though the language (say, "zh") may
      # be understood when spoken, the user can only *read* it if presented
      # in a specific script - so stripping out the script specifier might
      # well be worse than just giving up and going for the default locale.

      found = match.call( tag.language, tag.script, nil )
      return found unless found.nil?

    end # 'for code in codes'

    # Give up!

    return default_locale
  end

  # Decide which locale to use from the choice of the user's configured
  # languge, the primary language set for the user's configured location,
  # or the HTTP accept-language header, in that order.
  #
  # Pass a request object instance and a user object instance. Returns the
  # chosen language code as a symbol. Always returns a valid value from the
  # available locales according to the I18n module. See class function
  # 'set_best_locale' if you want to actually apply this code to use as the
  # current locale.
  #
  # If the given user value is "nil", only the HTTP header is considered.
  #
  def self.reconcile_user_data_with_http_request_language( request, user )
    list = []

    # Canvass doesn't use Locations like Artisan.
    #
    # unless ( user.nil? )
    #   list.push( user.language.code          ) unless ( user.language.nil? )
    #   list.push( user.location.language.code ) unless ( user.location.nil? || user.location.language.nil? )
    # end

    codes_from_header = request.user_preferred_languages()
    list.push( codes_from_header ) unless ( codes_from_header.nil? )

    return select_best_locale( list.flatten )
  end

  # Set the Rails locale to the best match for the given code. The code is
  # assumed to match an available translation. For ways of getting at such
  # codes, see class functions 'select_best_locale' and
  # 'reconcile_user_data_with_http_request_language'.
  #
  def self.set_best_locale( code )
    I18n.locale = code
  end
end
