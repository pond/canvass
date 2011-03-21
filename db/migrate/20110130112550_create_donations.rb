########################################################################
# File::    20110130112550_create_payments.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Create or destroy the 'donations' table.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class CreateDonations < ActiveRecord::Migration
  def self.up
    create_table :donations do | t |

      # There is a link back to the user who made the donation and the poll
      # they donated against. If either the poll or user get deleted in future,
      # important audit trail information about the user is copied into the
      # payment record as a backup.

      t.belongs_to :user # => integer user_id
      t.string     :user_name,       :null => false, :limit => User::MAXLEN_NAME
      t.string     :user_email,      :null => false, :limit => User::MAXLEN_EMAIL

      t.belongs_to :poll # => integer poll_id
      t.string     :poll_title,      :null => false, :limit => Poll::MAXLEN_TITLE

      # Donations must record the currency in case the poll goes away.
      
      t.belongs_to :currency # => integer currency_id

      # For the Workflow gem (see config/environment.rb).

      t.string     :workflow_state,  :null => false, :limit => Donation::MAXLEN_STATE

      # Some donations arise from redistribution of money from e.g. expired
      # polls and may have negative or positive amounts depending on whether
      # they've been taken from the expired poll or added to an open poll. The
      # "debit" flag indicates the amount removed from the poll that expired,
      # else it's a contribution to a poll which was open. The source poll ID
      # and title is given in the next two parameters.
      t.boolean    :redistribution,    :default => false
      t.boolean    :debit,             :default => false
      t.belongs_to :source_poll # => integer source_poll_id
      t.string     :source_poll_title, :limit => Poll::MAXLEN_TITLE

      # Monotonically rising invoice number, assigned via the InvoiceNumber
      # model mechanism and singleton instance when a purchase is committed.

      t.integer    :invoice_number

      # Some payment gateways let the payer leave a note for the payee.

      t.text       :notes

      # Authorisation tokens are needed in several places. For on-site payments
      # they're used to authorise and capture funds in separate phases which
      # avoids the need to store credit card details locally. Tokens for each
      # currency are pushed into a serialised array. Once funds are captured,
      # the authorisation tokens are stored in a hash keyed by ":onsite", with
      # the value itself a hash keyed by currency ID as a string with values
      # of the actual capture response authorisation tokens. These are used for
      # refunds later if necessary. Off-site payments use a similar hash, keyed
      # by ":offsite", to store the single currency payment transaction details
      # in case of refunds later.
      #
      # The code for this is adapted from Artisan and over-specified for this
      # model, wherein only a single currency and single combined action of
      # donation/voting/purchasing is made, so within Canvass things are often
      # more simple.

      t.text       :authorisation_tokens

      # In Artisan the Purchase model records purchases connected to a series
      # of order items related to shopping cart entries. Each of these carries
      # its cost, so the total purchase value is found from them. In Canvass,
      # just a single payment is made, so the amount is stored here directly.
      # A low accuracy float cache copy is kept for search and sort purposes.

      t.string     :amount_integer,  :null => false
      t.string     :amount_fraction, :null => false
      t.float      :amount_for_sorting

      t.timestamps
    end

    add_index :donations, :user_id
    add_index :donations, :poll_id
    add_index :donations, :currency_id

  end

  def self.down
    drop_table :donations
  end
end
