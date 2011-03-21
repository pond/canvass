########################################################################
# File::    users_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Look at locally defined users.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class UsersController < ApplicationController

  uses_prototype()
  uses_leightbox( :only => :index )

  @@hubssolib_permissions = HubSsoLib::Permissions.new( {
    :index   => [ :admin, :webmaster ],
    :show    => [ :admin, :webmaster ],
  } )

  def self.hubssolib_permissions
    @@hubssolib_permissions
  end

  # GET /users
  def index
    appctrl_search_sort_and_paginate( User )
  end

  # GET /users/1
  def show
    @user = User.find( params[ :id ] )
  end
end
