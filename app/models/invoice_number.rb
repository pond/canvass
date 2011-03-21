########################################################################
# File::    invoice_number.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: Keep track of invoice numbers. This is a singleton which
#           records a most recently used invoice number (or zero at the
#           very beginning). The integer invoice number is monotonically
#           increased with total thread-safety so that successive
#           invoices will get successive numbers without fail. The class
#           was originally created due to UK VAT invoice numbering
#           requirements.
# ----------------------------------------------------------------------
#           19-Mar-2010 (ADH): Created.
#           21-Feb-2011 (ADH): Imported from Artisan.
########################################################################

class InvoiceNumber < ActiveRecord::Base

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  before_create :enforce_singleton

  def enforce_singleton

    # OK, so this isn't particularly clever, but it's a lot lighter than
    # adding in some plugin like Acts As Singleton just to try and get an
    # analogue of the Ruby core Singleton module.
    #
    #   http://ruby-doc.org/stdlib/libdoc/singleton/rdoc/index.html

    raise "InvoiceNumber is a singleton" unless InvoiceNumber.count.zero?
  end

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # Not applicable.

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Generate the next invoice number. Returns the number to use in the given
  # invoice. Always use an outer transaction so that the invoice number can be
  # assigned to e.g. a purchase and if anything fails, including the creation
  # of the purchase object, the invoice number counter will be rolled back too.
  #
  def self.next!
    return InvoiceNumber.transaction do
      generator = InvoiceNumber.find( :first, :lock => true ) # ...and only!
      number    = ( generator.last_number_used += 1 )

      generator.save!

      number # Block evaluates to this
    end
  end
end
