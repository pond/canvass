########################################################################
# File::    20110130160059_create_invoice_numbers.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Create or destroy the 'invoice_numbers' table. This actually
#           holds a singleton which records a most recently used
#           invoice number (or zero at the very beginning). The model
#           code related to this table uses transactions and locking to
#           ensure that the integer invoice number is monotonically
#           increased with total thread-safety so that successive
#           invoices will get successive numbers without fail. The table
#           and model arise from UK VAT invoice numbering requirements.
# ----------------------------------------------------------------------
#           19-Mar-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

require 'yaml'
require 'active_record/fixtures'

class CreateInvoiceNumbers < ActiveRecord::Migration
  def self.up
    create_table 'invoice_numbers' do | t |
      t.integer :last_number_used, :null => false, :default => 0
    end

    # Define the default singleton.

    directory = File.join( RAILS_ROOT, 'test', 'fixtures' )
    Fixtures.create_fixtures( directory, 'invoice_numbers' )
  end

  # In a production system, dropping the invoice numbers table is fairly
  # suicidal since you'll lose the record of the last used invoice number
  # and new invoices will reuse numbers already issued. Provided you take
  # care to manually record the last used invoice number beforehand and
  # restore this in an offline system before going back online, though,
  # you should be able to get away with it.
  #
  def self.down
    drop_table 'invoice_numbers'
  end
end
