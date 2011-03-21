########################################################################
# File::    20090414121243_create_currencies.rb
# (C)::     Hipposoft 2009, 2010, 2011
#
# Purpose:: Create or destroy the 'currencies' table.
# ----------------------------------------------------------------------
#           14-Apr-2009 (ADH): Created.
#           18-Feb-2011 (ADH): Imported from Artisan.
########################################################################

class CreateCurrencies < ActiveRecord::Migration
  def self.up
    create_table 'currencies' do | t |
      t.string  :name,               :limit   => Currency::MAXLEN_NAME
      t.string  :code,               :limit   => Currency::MAXLEN_CODE

      t.string  :integer_template,   :limit   => Currency::MAXLEN_INTEGER_TEMPLATE
      t.string  :delimiter,          :limit   => Currency::MAXLEN_DELIMITER
      t.string  :fraction_template,  :limit   => Currency::MAXLEN_FRACTION_TEMPLATE

      t.integer :decimal_precision,  :null    => false,
                                     :default => Currency::DEFAULT_DECIMAL_PRECISION
      t.string  :rounding_algorithm, :null    => false,
                                     :default => Currency::DEFAULT_ROUNDING_ALGORITHM,
                                     :limit   => Currency::MAXLEN_ROUNDING_ALGORITHM

      t.string  :symbol,             :limit   => Currency::MAXLEN_SYMBOL
      t.boolean :show_after_number,  :null    => false,
                                     :default => Currency::DEFAULT_SHOW_AFTER_NUMBER
    end
  end

  def self.down
    drop_table 'currencies'
  end
end
