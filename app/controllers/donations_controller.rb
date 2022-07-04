########################################################################
# File::    donations_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Handle creating and displaying donations.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class DonationsController < ApplicationController

  @@hubssolib_permissions = HubSsoLib::Permissions.new( {
    :index  => [ :admin, :webmaster, :privileged, :normal ],
    :show   => [ :admin, :webmaster, :privileged, :normal ],
    :new    => [ :admin, :webmaster, :privileged, :normal ],
    :create => [ :admin, :webmaster, :privileged, :normal ]
  } )

  def self.hubssolib_permissions
    @@hubssolib_permissions
  end

  def skip_main_heading?
    action_name.to_sym == :index
  end

  # GET /donations
  # GET /users/<n>/donations
  def index

    # The Donation model takes care of permissions for users trying to view
    # the donations of other users and so-forth within its "conditions_for"
    # scope. If the user tries to hack around with URLs they might get an odd
    # title such as "All Donations", but the list will only contain things
    # they're allowed to see (e.g. for non-admins, only their donations).
    #
    appctrl_search_sort_and_paginate(
      Donation,
      scope: Donation.conditions_for( params, current_user )
    )
  end

  # GET /donations/<n>
  # GET /users/<u>/donations/<n>
  def show
    @donation = Donation.conditions_for( params, current_user ).find( params[ :id ] )
    redirect_to polls_path and return if @donation.nil?
  end

  # GET /polls/<n>/donations/new
  def new
    @poll     = Poll.find_by_id( params[ :poll_id ] )
    @donation = Donation.generate_for( @poll, current_user, '0', '0' )

    params[ :payment_method ] = current_user.admin? ? 'none' : 'onsite'
  end

  # POST /polls/<n>/donations
  def create
    payment_method = params[ :payment_method ]

    # This used to be used for donation creation with payment gateways
    # involved, but is now only used for the admin "register an external
    # donation" functionality.
    #
    # Everything else is done via bespoke PayPal code.
    #
    if payment_method != 'none' || current_user.admin? == false
      redirect_to root_path() and return
    end

    # Here, we know that the payment method parameter is valid and the
    # current user has permission to use whatever method was specified.
    #
    begin
      options = {
        :external => true,
        :name     => params[ :payment_none_donor_name  ],
        :email    => params[ :payment_none_donor_email ]
      }

      @poll     = Poll.find_by_id( params[ :poll_id ] )
      @donation = Donation.generate_for(
        @poll,
        current_user,
        params[ :donation ][ :amount_integer  ],
        params[ :donation ][ :amount_fraction ],
        options
      )

    rescue => error
      appctrl_report_error( error )
      redirect_to root_path()

    end

    saved = false

    Donation.transaction do
      saved = @donation.save

      if ( saved )
        @donation.notes          = t( :'uk.org.pond.canvass.controllers.donations.view_external_note' )
        @donation.invoice_number = InvoiceNumber.next!
        @donation.paid! # See Workflow state machine definitions in donation.rb

        saved = @donation.save
      end
    end

    if saved
      redirect_to( case payment_method
        when 'onsite'
          new_poll_payment_gateway_onsite_path( @poll )
        when 'offsite'
          new_poll_payment_gateway_offsite_path( @poll )
        when 'none'
          poll_path( @poll )
      end )
    else
      render :action => 'new'
    end
  end
end
