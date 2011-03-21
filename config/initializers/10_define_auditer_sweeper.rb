########################################################################
# File::    10_define_auditer_sweeper.rb
# (C)::     Hipposoft 2011
#
# Purpose:: A patch to copy a user's user name directly into an Audit
#           record so that both the User association and the name are
#           present. This makes searching easier and keeps meaningful
#           data available even if the User record is later deleted.
#
#           See also "app/models/auditer.rb" and
#                    "app/controllers/application_controller.rb".
# ----------------------------------------------------------------------
#           24-Feb-2011 (ADH): Created.
########################################################################

class AuditerSweeper < ActionController::Caching::Sweeper
  observe Audit

  def before_create( audit )
    audit.username = audit.user.name unless ( audit.user.nil? )
  end
end
