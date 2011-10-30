########################################################################
# File::    user.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Descriptions of users, cached from Hub information.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class User < ActiveRecord::Base

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  serialize :preferences

  has_many :polls
  has_many :donations

  MAXLEN_NAME  = 150
  MAXLEN_EMAIL = 200

  validates_presence_of   :name
  validates_length_of     :name,  :within  => 1..MAXLEN_NAME

  validates_presence_of   :email
  validates_uniqueness_of :email
  validates_length_of     :email, :within  => 6..MAXLEN_EMAIL # 6 => "r@a.wk"

  # Almost nothing is accessible to mass assignment.

  attr_accessible(
    :name
  )

  # See Jason King's "good_sort" plugin:
  #
  #   http://github.com/JasonKing/good_sort/tree/master
  #
  # Must use "table_exists?", as good_sort needs to check the database but
  # this class may be examined by migrations before the table is created.

  sort_on :name,
          :email,
          :admin if User.table_exists?

  # How many entries to list per index page? See the Will Paginate plugin:
  #
  #   http://wiki.github.com/mislav/will_paginate
  #
  def self.per_page
    MAXIMUM_LIST_ITEMS_PER_PAGE
  end

  # Search columns for views rendering the "shared/_simple_search.html.erb"
  # view partial and using "appctrl_build_search_conditions" to handle queries.

  SEARCH_COLUMNS = %w{name email}

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Apply a default sort to the given array of model instances. The array is
  # modified in place.
  #
  def self.apply_default_sort_order( array )
    array.sort! { | x, y | x.name <=> y.name }
  end

  # Get a value from the user's preferences hash. The hash is nested in a
  # similar manner to the I18n module's translation hashes and is addressed
  # in a similar way - pass a dot-separated key string, e.g. "foo.bar.baz".
  # Returns 'nil' for unset preferences, else the value at that location.
  #
  # Currently defined preferences include (but may not be limited to - this
  # list may be out of date) the following:
  #
  #   sorting => { <controller-name> => { <good_sort params hash entry> } }
  #
  #     Most recently recorded value of params[:sort] by an index action for
  #     a controller identified by <controller_name>. For more information see
  #     "appctrl_apply_sorting_preferences".
  #
  #   bounceback => nil or hash of bounceback data
  #
  #     Enforced visit of a particular URL is in progress unless nil. For more
  #     information see "appctrl_enable_bounceback".
  #
  #   masspay => nil or hash of mass payment data
  #
  #     A mass payment session is in progress unless nil. For more information
  #     see the Payment Bulk Onsite Controller.
  #
  def get_preference( key_str )
    keys = key_str.split( '.' )
    pref = self.preferences

    for key in keys
      return nil if pref.nil?
      pref = pref[ key ]
    end

    return pref
  end

  # Set the value of a preference identified as for "get_preference" above.
  # If any of the nested hashes identified by the key string are missing (e.g.
  # in example "foo.bar.baz", any of hashes "foo", "bar" or "baz") then
  # relevant entries in the preferences will be made automatically.
  #
  # The method saves 'self' back to database and returns the return value of
  # the call made to "save". Thus returns 'false' on failure, else 'true'.
  #
  # See also "set_preference!".
  #
  def set_preference( key_str, value )
    return set_preference_by_method!( key_str, value, :save )
  end

  # As "set_preference" but returns the result of a call to "save!", so raises
  # an exception on failure.
  #
  def set_preference!( key_str, value )
    return set_preference_by_method!( key_str, value, :save! )
  end

  # ===========================================================================
  # PRIVATE
  # ===========================================================================

private

  # Implement "set_preference" and "set_preference!" - pass the preference
  # key string, preference value and ":send" or ":send!" depending on the
  # method required for saving the preference changes.
  #
  def set_preference_by_method!( key_str, value, method )
    keys = key_str.split( '.' )
    root = self.preferences || {}
    pref = root

    keys.each_index do | index |
      key = keys[ index ]

      if ( index == keys.size - 1 )
        pref[ key ] = value
      else
        pref[ key ] ||= {}
        pref = pref[ key ]
      end
    end

    self.preferences = root
    return self.send( method )
  end
end
