class AddCommentToAudits < ActiveRecord::Migration[5.2]
  def self.up
    add_column :audits, :comment, :string
  end

  def self.down
    remove_column :audits, :comment
  end
end