########################################################################
# File::    polls_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Manage the poll list.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
#           16-Feb-2011 (ADH): Almost completely replaced with code
#                              imported from Artisan.
########################################################################

class PollsController < ApplicationController

  uses_prototype()
  uses_leightbox( :only => [ :index, :show ] )

  @@hubssolib_permissions = HubSsoLib::Permissions.new( {
    :create  => [ :admin, :webmaster ],
    :new     => [ :admin, :webmaster ],
    :edit    => [ :admin, :webmaster ],
    :update  => [ :admin, :webmaster ],
    :delete  => [ :admin, :webmaster ],
    :destroy => [ :admin, :webmaster ],
  } )

  def PollsController.hubssolib_permissions
    @@hubssolib_permissions
  end

  def skip_main_heading?
    [ :show, :index ].include?( action_name.to_sym )
  end

  # GET /polls
  # GET /users/<n>/polls
  def index
    @user            = nil
    extra_conditions = nil
    user_id          = params[ :user_id ]

    unless ( user_id.nil? )
      redirect_to polls_path and return unless ( current_user.admin? )

      @user = User.find_by_id( user_id )
      redirect_to polls_path and return if ( @user.nil? )

      extra_conditions = [ 'user_id = ?', @user.id ]
    end

    appctrl_search_sort_and_paginate(
      Poll,
      :default_sorting  => { 'down' => '', 'field' => 'workflow_state' },
      :extra_conditions => extra_conditions,
      :always_sort_by   => "\"polls\".#{ Poll.translated_column( :title ) }"
    )
  end

  # GET /polls/1
  def show
    @poll = Poll.find( params[ :id ] )

    # The following is for the admin-only nested donations list.

    if ( current_user.try( :admin? ) )
      params[ :poll_id ] = @poll.id
      appctrl_search_sort_and_paginate(
        Donation,
        :default_sorting  => Donation.default_sort_hash(),
        :extra_conditions => Donation.conditions_for( params, current_user )
      )
    end
  end

  # GET /polls/new
  def new
    @poll          = Poll.new
    @poll.currency = Currency.get_best_currency( current_user() )
  end

  # GET /polls/1/edit
  def edit
    @poll = Poll.find( params[ :id ] )
  end

  # POST /polls
  def create
    @poll                = Poll.new( params[ :poll ] )
    @poll.user           = current_user()
    @poll.votes          = 0
    @poll.total_integer  = '0'
    @poll.total_fraction = '0'

    Poll.transaction do
      if @poll.save
        appctrl_set_flash :notice
        redirect_to @poll
      else
        render :action => 'new'
      end
    end
  end

  # PUT /polls/1
  def update
    @poll = Poll.find( params[ :id ] )

    begin

      # Use a transaction to set the state and update the other attributes. We
      # have to do lots of checking on the allowed state and turn it into a
      # state transition method name. The Poll model may then do a lot of
      # processing depending upon the nature of the transition.

      result = Poll.transaction do
        new_state = params[ :poll ][ :workflow_state ]

        unless ( new_state.blank? )
          new_state = new_state.to_sym
          params[ :poll ].delete( :workflow_state )

          if ( @poll.allowed_new_states.include?( new_state ) )
            @poll.current_state.events.each do | event_name, event_action |
              if ( event_action.transitions_to.to_sym == new_state )
                @poll.send( "#{ event_name }!" )
              end
            end
          end
        end

        @poll.update_attributes( params[ :poll ] ) # Becomes value of transaction block
      end

    rescue => error

      # The "reload" makes sure that attempted but failed state changes are
      # noticed properly - database rollback isn't enough to update the model's
      # state table. We only expect the model to raise an empty error message,
      # which indicates that it's added a message to the 'state' attribute.
      # However, in the unlikely event that a different exception occurs, we
      # add this as an error connected with no specific attribute so that the
      # user can see what went wrong.

      @poll.reload
      @poll.errors.add_to_base( error.message ) unless error.message.empty?

      result = false

    end

    if ( result )
      appctrl_set_flash :notice
      redirect_to @poll
    else
      render :action => 'edit'
    end
  end

  # DELETE /polls/1
  def destroy
    @poll = Poll.find( params[ :id ] )

    if ( @poll.donations.count.zero? )
      @poll.destroy
      appctrl_set_flash :notice
      redirect_to( polls_url() )
    else
      appctrl_set_flash :error
      redirect_to( @poll )
    end
  end
end
