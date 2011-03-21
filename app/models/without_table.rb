########################################################################
# File::    without_table.rb
# (C)::     http://stackoverflow.com/questions/315850/rails-model-without-database/318919#318919
#
# Purpose:: Define a class which lets us use ActiveRecord validations
#           without needing a database representation of the model.
# ----------------------------------------------------------------------
#           16-Feb-2011 (ADH): Imported from Artisan.
########################################################################

class WithoutTable < ActiveRecord::Base

  self.abstract_class = true

  def self.columns
    @columns ||= [];
  end

  def self.column( name, sql_type = nil, default = nil, null = true )
    columns << ActiveRecord::ConnectionAdapters::Column.new(
      name.to_s,
      default,
      sql_type.to_s,
      null
    )
  end
end
