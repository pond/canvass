########################################################################
# File::    auditer.rb
# (C)::     Hipposoft 2011
#
# Purpose:: A subclass of Acts As Audited's "Audit" model which provides
#           additional properties required by the 'search, sort and
#           paginate' mechanism in Application Controller.
#
#           See also "config/initializers/10_define_auditer_sweeper.rb".
# ----------------------------------------------------------------------
#           23-Feb-2011 (ADH): Created.
########################################################################

class Auditer < Audit

  # See Jason King's "good_sort" plugin:
  #
  #   http://github.com/JasonKing/good_sort/tree/master
  #
  # Must use "table_exists?", as good_sort needs to check the database but
  # this class may be examined by migrations before the table is created.

  sort_on :auditable_type, :username, :action, :created_at if Audit.table_exists?

  # How many entries to list per index page? See the Will Paginate plugin:
  #
  #   http://wiki.github.com/mislav/will_paginate

  def self.per_page
    MAXIMUM_LIST_ITEMS_PER_PAGE
  end

  # Search columns for views rendering the "shared/_simple_search.html.erb"
  # view partial and using "appctrl_build_search_conditions" to handle queries.

  SEARCH_COLUMNS = %w{auditable_type username action changes}

end