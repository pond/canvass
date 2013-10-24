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

    # 'Events' is a hash of event names yielding event data. Collect this to
    # an array of key/value pairs and sort using the value's "transitions_to"
    # field. State names have "a_", "b_" etc. prefixes so that they sort in a
    # rational order for the progression from one state to another.

    events = item.current_state.events.dup.collect.sort do | a, b |
      a[ 1 ].transitions_to.to_s <=> b[ 1 ].transitions_to.to_s
    end

    # Generate a menu from this array using the translated event name for the
    # visible text and the state name to which the item should be transitioned
    # as the associated form value. We use the sorted array from above rather
    # than the raw events data as the raw events hash is not sorted by logical
    # transition order (hashes are not inherently sorted and event names do
    # not have the sortable prefix convention used for state names).

    form.select(
      :workflow_state,
      events.collect { | event |
        event_name = event[ 0 ]
        event_data = event[ 1 ]
        [ apphelp_event( event_name, PollsController ), event_data.transitions_to ]
      }.unshift( blank_entry ),
      :selected => ''
    )
  end
end
