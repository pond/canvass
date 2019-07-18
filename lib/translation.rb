########################################################################
# File::    translation.rb
# (C)::     Hipposoft 2009, 2010, 2011, 2019
#
# Purpose:: Lightweight support for Traco gem's translatable columns.
# ----------------------------------------------------------------------
#           16-Feb-2011 (ADH): Imported from Artisan.
#           18-Jul-2019 (ADH): Moved into 'lib'.
########################################################################

class Translation

  # If Model.respond_to?( :columns_for_translation ) then call with the name
  # of a column to get a locale-specific version returned (will be the same
  # name if the column name isn't translated, or will have a locale suffix).
  # For example, call with "title" to get "title_en", or with untranslated
  # column "foo" to get "foo" back again. The Traco gem's comparable method
  # always just adds the locale suffix regardless of whether or not the
  # column is actually translated.
  #
  def self.translated_column( model, name )
    if ( model.columns_for_translation.include?( name.to_s ) )
      model.current_locale_column( name )
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
end
