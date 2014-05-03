########################################################################
# File::    donations_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Handle creating and displaying donations.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class DonationsController < ApplicationController

  uses_prototype()
  uses_leightbox( :only => :index )

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
    # class method. If the user hacks around with URLs they might get an odd
    # title such as "All Donations", but the list will only contain things
    # they're allowed to see (e.g. for non-admins, only their donations).

    appctrl_search_sort_and_paginate(
      Donation,
      :default_sorting  => Donation.default_sort_hash(),
      :extra_conditions => Donation.conditions_for( params, current_user )
    )
  end

  # GET /donations/<n>
  # GET /users/<u>/donations/<n>
  def show
    @donation = Donation.find_by_id(
      params[ :id ],
      :conditions => Donation.conditions_for( params, current_user )
    )

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

    redirect_to root_path() and return if (
      %w{ none onsite offsite }.include?( payment_method ) == false ||
      ( payment_method == 'none' && current_user.admin? == false )
    )

    # Here, we know that the payment method parameter is valid and the
    # current user has permission to use whatever method was specified.

    begin
      options = {}

      if ( payment_method == 'none' )
        options[ :external ] = true
        options[ :name     ] = params[ :payment_none_donor_name  ]
        options[ :email    ] = params[ :payment_none_donor_email ]
      end

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

    saved = @donation.save

    if ( saved && payment_method == 'none' )
      saved = Donation.transaction do
        @donation.notes          = t( :'uk.org.pond.canvass.controllers.donations.view_external_note' )
        @donation.invoice_number = InvoiceNumber.next!
        @donation.paid! # See Workflow state machine definitions in donation.rb
        @donation.save
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
