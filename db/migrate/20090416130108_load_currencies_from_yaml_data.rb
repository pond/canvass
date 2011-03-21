########################################################################
# File::    20090416130108_load_currencies_from_yaml_data.rb
# (C)::     Hipposoft 2009, 2010, 2011
#
# Purpose:: Load an initial data set into the 'currencies' table.
# ----------------------------------------------------------------------
#           16-Apr-2009 (ADH): Created.
#           18-Feb-2011 (ADH): Imported from Artisan.
########################################################################

require 'yaml'
require 'active_record/fixtures'

class LoadCurrenciesFromYamlData < ActiveRecord::Migration

  # Note that this is an aggressive and rather stupid migration. If someone
  # had run this migration, added various currencies and later decided to roll
  # back the migration, they might be surprised to find that it deletes *all*
  # currencies, not just the ones it added. That's pretty nasty.
  #
  #TODO Improve LoadCurrenciesFromYamlData 'down' code, if it seems worthwhile.

  def self.up
    directory = File.join( RAILS_ROOT, 'test', 'fixtures' )
    Fixtures.create_fixtures( directory, 'currencies' )

    # Canvass doesn't use Locations like Artisan.
    #
    # # Associate some of the basic currencies with locations, if locations can
    # # be found.
    # 
    # Currency.establish_predefined_associations
  end

  def self.down
    Currency.delete_all
  end
end
