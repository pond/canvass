########################################################################
# File::    donations_helper.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Utility methods for views related to Donations.
# ----------------------------------------------------------------------
#           22-Feb-2011 (ADH): Created.
########################################################################

module DonationsHelper

  # Return text suitable for a link, button or heading when wanting to list
  # donations restricted by the given User or user ID - e.g. "Your donations" 
  # vs "<Foo>'s donations" if a user ID specifies the current user or another
  # user. Pass "nil" for a generic string - e.g. "All donations".
  #
  # The returned string is HTML-safe, with any sensitive characters escaped.
  #
  def donationshelp_index_text( user_or_id )
    user_or_id = User.find_by_id( user_or_id ) unless ( user_or_id.is_a? User )

    if ( user_or_id.nil? )
      apphelp_heading( DonationsController, :index )
    elsif ( user_or_id.id == current_user.try( :id ) )
      apphelp_view_hint( :your_donations, DonationsController )
    else
      apphelp_view_hint( :other_donations, DonationsController, :name => h( user_or_id.name ) )
    end
  end

  # Return an HTML-safe description of a user's name from a given Donation
  # record, linking to the Users Controller's "show" action for that User if
  # the object still exists.
  #
  def donationshelp_user_link( donation )
    if ( donation.user.nil? )
      h( donation.user_name )
    elsif ( donation.user_name != donation.user.name )
      t(
        :'uk.org.pond.canvass.generic_messages.via',
        :one => h( donation.user_name ),
        :two => link_to( h( donation.user.name ), donation.user )
      ).html_safe()
    else
      link_to( h( donation.user_name ), donation.user )
    end
  end

  # Return an HTML-safe description of a poll's title from a given Donation
  # record, linking to the Polls Controller's "show" action for that Poll if
  # the object still exists.
  #
  def donationshelp_poll_link( donation )
    if ( donation.poll.nil? )
      h( donation.poll_title )
    else
      link_to( h( donation.poll_title ), donation.poll )
    end
  end

  # As "donationshelp_poll_link" but handles the slightly more fiddly case of
  # the source poll for redistribution credit donations.
  #
  def donationshelp_source_poll_link( donation )
    if ( Poll.find_by_id( donation.source_poll_id ).nil? )
      h( donation.source_poll_title )
    else
      link_to( h( donation.source_poll_title ), poll_path( :id => donation.source_poll_id ) )
    end
  end

end
