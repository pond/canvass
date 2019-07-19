# Canvass prior to the Rails 5 update supported translatable columns for
# Poll titles and descriptions, so that in theory one poll object could
# be given several different language descriptions to aid a visitor. This
# was only ever really experimental, didn't work that well and was not
# well (or even really at all) supported by the GUI. For the Rails 5
# rebuild, to save time, this feature is being removed.
#
# If you were using it, sorry :-( let me know via a GitHub Issue:
#
#   https://github.com/pond/canvass/issues
#
# ...and I will look into it. Only the "title_en"/"description_en" columns
# are renamed here, so any other language columns that might've been added
# will not be touched - no data is lost - so an alternative implementation
# in future is not ruled out.
#
class RemoveTranslatableColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :polls, :title_en, :title
    rename_column :polls, :description_en, :description
  end
end
