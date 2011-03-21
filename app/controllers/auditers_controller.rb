########################################################################
# File::    auditers_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Manage the display of audit information.
# ----------------------------------------------------------------------
#           23-Feb-2011 (ADH): Created.
########################################################################

class AuditersController < ApplicationController

  uses_prototype( :only => :index )
  uses_leightbox( :only => :index )

  @@hubssolib_permissions = HubSsoLib::Permissions.new( {
    :index  => [ :admin, :webmaster ]
  } )

  def self.hubssolib_permissions
    @@hubssolib_permissions
  end

  def index
    appctrl_search_sort_and_paginate(
      Auditer,
      :default_sorting => { 'down' => 'true', 'field' => 'created_at' }
    )
  end
end
