########################################################################
# File::    20110130112310_create_users.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Create or destroy the 'users' table.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do | t |
      t.string  :name,  :null => false, :limit => User::MAXLEN_NAME
      t.string  :email, :null => false, :limit => User::MAXLEN_EMAIL
      t.boolean :admin, :default => false

      t.text    :preferences # Default sort orders etc.; serialised Ruby hash is stored here

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
