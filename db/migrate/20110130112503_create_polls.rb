########################################################################
# File::    20110130112503_create_polls.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Create or destroy the 'polls' table.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class CreatePolls < ActiveRecord::Migration
  def self.up
    create_table :polls do |t|

      # See "prepare_model_for_translation" in "translations_controller.rb" and
      # the Poll model. The following is equivalent to:
      #
      #   t.string :title_<default-locale-code>, :limit => Poll::MAXLEN_TITLE
      #   t.text   :body_<default-locale-code>

      t.column Poll.column_name_localized( 'title', I18n.default_locale() ).to_sym,
               Poll.column_type( :title ),
               Poll.column_options( :title )

      t.column Poll.column_name_localized( 'description', I18n.default_locale() ).to_sym,
               Poll.column_type( :description ),
               Poll.column_options( :description )

      t.integer :votes

      # Link back to the administrator who created this poll and the currency
      # the poll supports for donations.

      t.belongs_to :user     # => integer user_id
      t.belongs_to :currency # => integer currency_id

      # For the Workflow gem (see config/environment.rb).

      t.string  :workflow_state, :null => false, :limit => Poll::MAXLEN_STATE

      # A high accuracy count of the running total in this poll has to be
      # kept. If the poll gets closed by expiry, the amount has to be
      # distributed amongst any other live polls. A cache column float value
      # is kept for sort and search purposes.

      t.string  :total_integer,  :null => false
      t.string  :total_fraction, :null => false
      t.float   :total_for_sorting

      t.timestamps
    end

    add_index :polls, :user_id
    add_index :polls, :currency_id

  end

  def self.down
    drop_table :polls
  end
end
