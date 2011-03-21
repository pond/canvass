########################################################################
# File::    currencies_controller.rb
# (C)::     Hipposoft 2009, 2010, 2011
#
# Purpose:: Manage the currency list.
# ----------------------------------------------------------------------
#           14-Mar-2009 (ADH): Created.
#           18-Feb-2011 (ADH): Imported from Artisan.
########################################################################

class CurrenciesController < ApplicationController

  uses_prototype( :only => :index )
  uses_leightbox( :only => :index )

  @@hubssolib_permissions = HubSsoLib::Permissions.new( {
    :index   => [ :admin, :webmaster ],
    :show    => [ :admin, :webmaster ],
    :create  => [ :admin, :webmaster ],
    :new     => [ :admin, :webmaster ],
    :edit    => [ :admin, :webmaster ],
    :update  => [ :admin, :webmaster ],
    :delete  => [ :admin, :webmaster ],
    :destroy => [ :admin, :webmaster ],
  } )

  def CurrenciesController.hubssolib_permissions
    @@hubssolib_permissions
  end

  # GET /currencies
  def index
    appctrl_search_sort_and_paginate( Currency )
  end

  # GET /currencies/1
  def show
    @currency = Currency.find( params[ :id ] )
  end

  # GET /currencies/new
  def new
    @currency = Currency.new
  end

  # GET /currencies/1/edit
  def edit
    @currency = Currency.find( params[ :id ] )
  end

  # POST /currencies
  def create
    @currency = Currency.new( params[ :currency ] )

    if @currency.save
      appctrl_set_flash :notice
      redirect_to @currency
    else
      render :action => 'new'
    end
  end

  # PUT /currencies/1
  def update
    @currency = Currency.find( params[ :id ] )

    if @currency.update_attributes( params[ :currency ] )
      appctrl_set_flash :notice
      redirect_to @currency
    else
      render :action => 'edit'
    end
  end

  # DELETE /currencies/1
  def destroy
    @currency = Currency.find( params[ :id ] )

    if ( Currency.count > 1 && @currency.polls.count.zero? && @currency.donations.count.zero? )
      @currency.destroy
      appctrl_set_flash :notice
    else
      appctrl_set_flash :error
    end

    redirect_to currencies_url()
  end
end
