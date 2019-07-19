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

class Auditer < Audited::Audit

  # Searching and sorting is via Ransack, with a cross-column set of search
  # parameters aliased as "simple".

  DEFAULT_SORT = 'created_at DESC'
  SIMPLE_SEARCH_FIELD = :auditable_type_username_or_action_or_audited_changes
  ransack_alias :simple, SIMPLE_SEARCH_FIELD

end