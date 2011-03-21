########################################################################
# File::    polls_helper.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Utility methods for views related to Polls.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

module PollsHelper

  # Return text suitable for a link, button or heading when wanting to list
  # polls created by a given user - e.g. "Your polls" vs "<Foo>'s polls".
  # Pass "nil" for a generic string - e.g. "All polls".
  #
  # The returned string is HTML-safe, with any sensitive characters escaped.
  #
  def pollshelp_index_text( user )
    if ( user.nil? )
      apphelp_heading( PollsController, :index )
    elsif ( user.id == current_user.try( :id ) )
      apphelp_view_hint( :your_polls, PollsController )
    else
      apphelp_view_hint( :other_polls, PollsController, :name => h( user.name ) )
    end
  end

  # Called via shared/_simple_search.html.erb due to its appearance in
  # Poll::SEARCH_COLUMNS. Generates HTML used to search for a workflow
  # state. Passed the ID to use for the field and the current field value.
  #
  def pollhelp_search_states( id, value )
    ctrl        = PollsController
    blank_entry = [
      t( :'uk.org.pond.canvass.search.menu_blank' ),
      ''
    ]

    select_tag(
      id,
      options_for_select(

        # The use of "states.keys" gives us an array of state names as symbols;
        # reject the 'initial' state, then collect the remainder into pairs of
        # internal state name and human-readable state name. Finally, add the
        # blank menu entry array at the start of the collection.

        Poll.workflow_spec.states.keys.reject { | state |
          state == Poll::STATE_INITIAL
        }.collect { | state |
          [ apphelp_state( state, ctrl ), state.to_s ]
        }.unshift( blank_entry ),

        :selected => ( value || '' )
      )
    )
  end

  # Return a SELECT menu for the given form, representing the given poll item,
  # according to its current state and, consequently, the states to which it
  # may be set.
  #
  def pollshelp_state_change_menu( form, item )
    blank_entry = [
      apphelp_view_hint( :menu_no_change, PollsController ),
      ''
    ]

    form.select(
      :workflow_state,
      item.allowed_new_states.collect { | state |
        [ apphelp_state( state, PollsController ), state ]
      }.unshift( blank_entry ),
      :selected => ''
    )
  end 
end
