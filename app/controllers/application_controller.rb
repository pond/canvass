########################################################################
# File::    application_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Common Rails controller actions.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  # Include all helpers, all the time; make some methods available to views.
  helper        :all
  helper_method :logged_in?
  helper_method :current_user

  # See ActionController::RequestForgeryProtection for details.
  protect_from_forgery

  filter_parameter_logging :card_type,
                           :card_number,
                           :card_cvv,
                           :card_to,
                           :card_from,
                           :card_issue

  # Hub single sign-on support.

  require 'hub_sso_lib'
  include HubSsoLib::Core

  before_filter :hubssolib_beforehand
  after_filter  :hubssolib_afterwards

  # https://github.com/collectiveidea/acts_as_audited/issues/26 - "Audt record
  # has no user on first request posted to a server". Recommended workaround is
  # included below. We take advantage of this in passing by defining another
  # sweeper (see "config/initializers/10_define_auditer_sweeper.rb") which adds
  # a copy of a User's name into an Audit record so that the record still has
  # useful data present even if the associated User is later deleted.

  require 'acts_as_audited/audit'
  require 'acts_as_audited/audit_sweeper'

  cache_sweeper :audit_sweeper,   :only => [ :create, :update, :destroy ]
  cache_sweeper :auditer_sweeper, :only => [ :create, :update, :destroy ]

  # Other filters

  before_filter :assign_real_user
  before_filter :set_best_locale
  before_filter :set_language_dependent_sorting
  before_filter :set_email_host_and_protocol
  before_filter :run_garbage_collectors

  # List of models which have translatable columns.

  APPCTRL_TRANSLATABLE_MODELS = [ Poll ]

  # Should the main heading output be suppressed in the master layout? Return
  # 'true' if so, else 'false'. Defined as 'false' here - subclasses should
  # override this if necessary.
  #
  def skip_main_heading?
    false
  end

  # Is there a currently logged in user? Returns 'true' if so, else 'false'.
  #
  def logged_in?
    hubssolib_logged_in?
  end

  # Return the current *Canvass* user, which is mapped to a Hub user. Will be
  # nil if not logged in, though you should check "logged_in?" first rather
  # than rely on this.
  #
  # See also before_filter-called "assign_real_user()".
  #
  def current_user
    @current_user
  end

protected

  # Set the Flash with an internationalised message describing the current
  # controller's current action's result. The result code is compiled into a
  # token string including the current controller and action names. This is
  # then looked up in the current translation data.
  #
  def appctrl_set_flash( result )

    # E.g. for controller name "users", action name "edit", result "notice":
    #      uk.org.pond.canvass.controllers.users.action_notice_edit

    flash[ result ] = t( "uk.org.pond.canvass.controllers.#{ controller_name }.action_#{ result }_#{ action_name }" )
  end

  # Report a serious unexpected error (pass the error details, e.g. "foo" from
  # Ruby code "rescue => foo", or some specific error string).
  #
  def appctrl_report_error( error )
    flash[ :error ] = t(
      :'uk.org.pond.canvass.generic_messages.error_prefix',
      :error => ERB::Util.html_escape( error )
    )
  end

  # Apply sorting preferences for the good_sort plugin by reading the current
  # user's preference data or applying a default sort hash passed into the
  # mandatory first parameter, provided that sort data is not already
  # specified in the params hash. If the params hash *does* contain such data
  # it is saved in the current user preferences (if a current user exists).
  #
  # Defaults hash format: { "name" => <column name>, "down" => <'' or 'true'> }
  #
  # The optional second parameter is the name to use when looking up the user's
  # search preferences. If not specified, the current request's controller's
  # name will be used. You may prefer to specify e.g. the table name of the
  # model which is being searched, so that preferences are associated with the
  # model rather than with the controller - a controller is only loosely
  # associated with a model, after all.
  #
  # See also "appctrl_search_sort_and_paginate".
  #
  def appctrl_apply_sorting_preferences( defaults, name = controller_name )

    # Retrieve a sort order specified in the params hash, if any.

    sort = params[ :sort ]

    if ( sort.nil? )

      # If that failed, use current user preferences if there is both a user
      # and a set preference, else defaults; write back into the params hash
      # for the caller's benefit.

      sort = current_user.get_preference( "sorting.#{ name }" ) if ( logged_in? )
      params[ :sort ] = sort || defaults

    else

      # Sorting data came from params - may not match existing user preferences
      # so save it. The return value of the save attempt is ignored because if
      # it fails there isn't much we can do to recover and a failure to save
      # column sort order is considered fairly unimportant (although it may
      # well point to much more serious underlying database problems).

      current_user.set_preference( "sorting.#{ name }", sort ) if ( logged_in? )

    end
  end

  # When a form created by view partial "shared/_simple_search.html.erb" is
  # submitted, call here to generate a search conditions array based on the
  # parts of the "params" hash related to the search form.
  #
  # Pass a model defining constant SEARCH_COLUMNS as the array of names, as
  # strings, use for the ":fields" array specified in the location variables
  # used to render the search form view partial. This is used as a security
  # measure - if someone tries to alter the search query data to examine other
  # columns, it won't work because only those columns specified by both the
  # constructed view and the target model will be involved. If the model
  # supports translatable columns, use the untranslated column names here. The
  # special use of "#" in names is supported (see the method description of
  # "appctrl_search_sort_and_paginate" for more details).
  #
  # Returns an array containing a conditions SQL fragment with substitution
  # placeholders and the set of values which should be substituted in - passing
  # this as a value for the ":conditions" parameter in a call to "find()" or
  # similar will result in the results set being restricted accordance with the
  # user's settings in the search form.
  #
  # If you pass a block, it will be called for each of the search parameters
  # (in an undetermined order) and passed a string giving the column name of
  # the search parameter in consideration right now. This lets you map virtual
  # columns for search - for example if you split a postal address into lots
  # of distinct fields in a model, you might allow searches on a fake column
  # name of "address". When this name is passed to your block, generate an SQL
  # fragment parameter substitution markers of "?" where required (for multiple
  # real columns masquerading as one real virtual column, you will typically
  # return something like "column_a LIKE ? OR column_b LIKE ? OR ...etc.". This
  # function will take your SQL data, count the "?"s in it, make sure that the
  # value supplied by the user for the virtual column is substituted safely
  # into each of the places where "?" appears and enclose your SQL fragment in
  # parentheses automatically so that precedence and logic of any other
  # surrounding SQL will be maintained.
  #
  # If your block is happy with a default "column LIKE ?"-style SQL fragment
  # then it should evaluate to "nil". If all your columns are simple cases,
  # don't bother passing a block at all.
  #
  # Special consideration is given to float and integer column types and
  # correct SQL is generated in such cases ("foo IS <unquoted-value>").
  #
  # Note that columns with a blank associated search value are skipped entirely
  # - if you do supply a block, it won't be called for that column (there's no
  # point).
  #
  # IMPORTANT: Since databases disagree on whether or not the "LIKE" operator
  # should be case sensitive, comparisons are forced to case *insensitive* via
  # "LOWER" on both column name and value to ensure consistent application
  # behaviour across databases. You should consider doing this in SQL returned
  # from a block if you pass one - e.g. use "LOWER(column_name) LIKE LOWER(?)"
  # instead of just "column_name LIKE ?".
  #
  # See also "appctrl_search_sort_and_paginate".
  #
  def appctrl_build_search_conditions( model )

    # All search-related keys start with "s_". The next character is a number
    # or letter which causes "sort" to organise keys in the order specified in
    # the view. An associated key "sr_" carries "and" or "or" for the radio
    # button selection for that entry, or neither of these if there is no radio
    # button (the first search term).

    conditions = []
    query      = ''
    first      = true
    columns    = model::SEARCH_COLUMNS
    translate  = model.respond_to?( :columns_for_translation )

    columns.each do | column |

      # Fields with a "#" inside have a method name to call to generate the
      # form data.

      array = column.split( '#' )

      if ( array.size > 1 )
        column           = array.first
        generator_method = array.last
      else
        generator_method = nil
      end

      column = model.translated_column( column ) if ( translate )
      value  = params[ "s_#{ column }".to_sym ]
      next if ( value.blank? )

      radio = params[ "sr_#{ column }".to_sym ]

      # If this is the first search term with a non-empty value then the radio
      # button and/or state is irrelevant and must be suppressed to avoid
      # invalid SQL generation later.

      if ( first )
        radio = ''
        first = false
      end

      # Make sure the value is an appropriate type.

      klass = model.columns_hash[ column ].klass # Ruby type representing column

      if ( klass == Fixnum )
        value = value.to_i
      elsif ( klass == Float )
        value = value.to_f
      else
        value = "%#{ value }%"
      end

      # If a block is given then call it, passing the column name. It should
      # evaluate to "nil" or a string.

      caller_sql = yield( column ) if ( block_given? )

      if ( caller_sql.nil? )
        klass = model.columns_hash[ column ].klass # Ruby type representing column

        if ( klass == Fixnum || klass == Float )
          sql_fragment = "#{ column } = ?"
        else
          sql_fragment = "LOWER(#{ column }) LIKE LOWER(?)"
        end

        conditions.push( value )
      else
        sql_fragment = caller_sql
        conditions   = conditions + ( [ value ] * caller_sql.count( '?' ) )
      end

      # Map radios manually, rather than with "radio.uppercase" or whatever -
      # the values come from the form submission so cannot be trusted. Someone
      # might try inserting bits of SQL in there to hack the site.

      case radio
      when "and": sql_fragment = " AND (#{ sql_fragment })"
      when "or":  sql_fragment =  " OR (#{ sql_fragment })"
      else        sql_fragment =      "(#{ sql_fragment })"
      end

      query << sql_fragment
    end

    # Push the conditions string onto the front of the array as this is what
    # the ":conditions" parameter in "find()" et al will expect.

    return conditions.unshift( query )
  end

  # Do the common work for an AJAX-sortable, search-filtered and paginated
  # list of options rendering via a "_list.html.erb" partial for XHR requests.
  #
  # Pass a model. This must use good_sort to provide a "sort_by" method for any
  # column used for sorting. It must define constant SEARCH_COLUMNS to an array
  # of names of any columns to be used for searching (see e.g. the Language,
  # Category or User models for examples of varying complexity). Special case:
  # A string in SEARCH_COLUMNS containing a hash defines the name of the search
  # column before the hash then a method to use to generate the HTML for the
  # search field afterwards. See "shared/_simple_search.html.erb" for the
  # practical use of this.
  #
  # The method then assigns "@items" from sending a method given in the options
  # hash to a base object also given in the options parameter. For example pass
  # "Location" and ":roots" to get a list of the root Location objects, or pass
  # "@location" and ":children" to get a list of the immediate children of
  # whatever nested set object instance is in "@location". Options keys:
  #
  #   :base_obj   => Object on which to call the method...
  #   :method     => ...specified here.
  #   :method_arg => Optional single argument value; will be passed to :method
  #                  if given (may be nil, in which case nil will be passed as
  #                  a single argument; or omitted, in which case :method is
  #                  called with no arguments).
  #   :include    => Optional value for :includes in the "find" call, to use
  #                  eager loading of associations. For example, a User list
  #                  may want to eager-load associated role and profile data,
  #                  so would specify ":include => [ :role, :profile ]".
  #
  # If the base object parameter is omitted then it is assumed to carry the
  # same value as the model given in the first parameter.
  #
  # If the method is omitted then "paginate" (from the will_paginate plugin) is
  # called on the model directly. This is more efficient than passing a method
  # name of ":all" (which is trapped as a special case for that reason).
  #
  # User sorting preferences for the calling controller are recorded and/or
  # applied in passing, with a default setting of "ascending, by 'name'". If
  # your model has other requirements then pass a default sort options hash in
  # the options:
  #
  #   :default_sorting => Optional default sort order hash, as described below.
  #   :always_sort_by  => Optional string to append to an ORDER BY clause, e.g.
  #                       for a User model, passing '"users".name' leads to
  #                       users being sorted by whatever good_sort column is in
  #                       use, then by ascending user name. NOTE: This may lead
  #                       to the same order value being specified twice. To try
  #                       and avoid that, if the order-by string already
  #                       contains a case-*sensitive* match of the always-sort
  #                       string, the latter is NOT appended. Thus it is best
  #                       to specify just the always-sort column name and *not*
  #                       include 'ASC' or 'DESC' in there (so you're limited
  #                       to implicit ascending sort order) to avoid ending up
  #                       with orders like "name ASC, name DESC". In this
  #                       example, giving just "name" would match orders of
  #                       "name" or "name DESC" and not be appended, thus doing
  #                       the Right Thing.
  #
  # The hash has string keys and values; key 'down' should have a value of an
  # empty string or 'true' (as a string) for ascending or descending order
  # respectively; key 'field' should have a value of the name of the column (as
  # a string, not symbol) for sorting.
  #
  # Callers may want to use a custom block for a call made internally to
  # "appctrl_build_search_conditions" - see that method for details - if so,
  # add that block in your call here, to "appctrl_search_sort_and_paginate",
  # and it will be passed straight on to (and ultimately called from)
  # "appctrl_search_sort_and_paginate". Search conditions may be further
  # augmented by static search query data specified in the options as follows:
  #
  #   :extra_conditions => An array of SQL query string and zero or more
  #                        arguments to substitute in. The query string will
  #                        be set before any search query, with the search
  #                        query added with "AND (...query...)".
  #
  # In the event that searching is in progress (a search query restriction is
  # in effect), "@search_results" will be set to 'true'. Views may find this
  # useful, particularly if no items are returned from a search attempt.
  #
  def appctrl_search_sort_and_paginate( model, options = {} )
    base_obj         = options.delete( :base_obj         ) || model
    method           = options.delete( :method           ) || :all
    includes         = options.delete( :include          ) || {}
    default_sorting  = options.delete( :default_sorting  ) || { 'down' => '', 'field' => 'name' }
    always_sort_by   = options.delete( :always_sort_by   )
    extra_conditions = options.delete( :extra_conditions )
    is_translatable  = model.respond_to?( :columns_for_translation )

    # We use a 'tableized' model name for the preferences key so that subclass
    # models work OK - e.g. "Auditer", a subclass of "Audit".

    appctrl_apply_sorting_preferences( default_sorting, model.model_name.tableize )

    # Build search conditions and merge with caller-supplied extra conditions.

    search_query = appctrl_build_search_conditions( model ) do | column |
      if block_given?
        yield( column )
      else
        nil
      end
    end

    @search_results = ! search_query.flatten.join.empty?

    unless ( extra_conditions.nil? )
      str = search_query[ 0 ]

      if ( str.empty? )
        str = extra_conditions[ 0 ]
      else
        str = "( #{ extra_conditions[ 0 ] } ) AND ( #{ str } )"
      end

      search_values = search_query[ 1..-1 ]     || []
      extra_values  = extra_conditions[ 1..-1 ] || []

      search_query = [ str ] + extra_values + search_values
    end

    # Compile the pagination options based on the above data and fetch the
    # relevant item list. Note that the column name for sorting may need to
    # be patched up if the model supports translatable columns, so do this
    # in passing.

    sort_params = params[ :sort ]

    if ( is_translatable && ! sort_params.nil? )
      column = sort_params[ 'field' ]

      # The user may have sorted on this column with language settings for a
      # particular locale, causing the locale-specific name to be saved in the
      # user's preferences. If the locale configuration later changes - e.g.
      # user changes languages or a new translation is added which better
      # matches the user's specified language - the code would then fail as it
      # would try to access a sorting column which didn't match the name based
      # on the new current locale. Thus, convert the column name to a locale
      # netural form, then get the definitely-for-this-locale version.

      unless ( column.nil? )
        column = model.untranslated_column( column ) # Make locale neutral...
        column = model.translated_column( column )   # ...then match current locale

        sort_params[ 'field' ] = column
      end
    end

    pagination_options = model.sort_by( sort_params )

    unless ( always_sort_by.nil? )
      order = pagination_options[ :order ] || ''

      unless ( order.include? always_sort_by )
        order += ', ' unless order.blank?
        pagination_options[ :order ] = order + always_sort_by
      end
    end

    pagination_options.merge!( {
      :page       => params[ :page ],
      :conditions => search_query,
      :include    => includes
    } )

    if ( method == :all )
      @items = base_obj.paginate( pagination_options )
    elsif ( options.has_key?( :method_arg ) )
      @items = base_obj.send( method, options.delete( :method_arg ) ).paginate( pagination_options )
    else
      @items = base_obj.send( method ).paginate( pagination_options )
    end

    # Render the default index.html.erb view for normal requests or, for AJAX
    # requests, render the list table partial.

    if ( request.xhr? )
      return render( :partial => "#{ model.model_name.tableize }/list" )
    end
  end

  # Make sure that "params[ :id ]" retrieves an object where "user_id" is equal
  # to the ID of the current user. If not, an authorisation failure will be
  # forced, unless the current user is an administrator. Usually called as a
  # before_filter method for edit-like or destroy-like actions only.
  #
  # There must be a current user - a previous item in the filter chain must
  # ensure this.
  #
  # On exit, either the controller will exit because the role requirements
  # were not satisfied, or the current action proceeds with "@item" set to the
  # looked up model.
  #
  def appctrl_ensure_is_owner
    model = controller_name.camelize.singularize.constantize # :-)
    @item = model.find( params[ :id ] )

    if ( @item.user_id != current_user.id )
      render_optional_error_file( 401 ) unless current_user.is_admin?
    end
  end

private

  # What do we do if access is denied? Pretend the location never existed if
  # logged in, else redirect for login.
  #
  def access_denied
    if ( user_signed_in? )
      render :file   => File.join( RAILS_ROOT, 'public', '404.html' ),
             :status => :not_found
    else
      authenticate_user!
    end
  end

  # Local User objects exist to manage associations between users, donations
  # and polls, among other things. That means we need to lazy-create users if
  # a Hub logged in user arrives who has no current database representation;
  # or we need to dig out that user's information. See "current_user" for how
  # this information is eventually exposed to other parts of the system.
  #
  def assign_real_user
    if ( hubssolib_logged_in? && @current_user.nil? )

      email = hubssolib_get_user_address()
      name  = hubssolib_unique_name()
      roles = hubssolib_get_user_roles()

      # Not internationalised since these are Should Never Happen exceptions
      # and in production mode, all the user would see is a 500 error.

      raise "Current Hub user appears to have no e-mail address" if ( email.nil? )
      raise "Current Hub user's name is unkonwn"                 if ( name.nil?  )
      raise "Current Hub user's roles are unknown"               if ( roles.nil? )

      user = User.find_by_email( email ) # Want to associate payments by e-mail address
                                         # since that's the primary association for e.g.
                                         # PayPal, even though we're also using a human
                                         # readable person's name that's been made
                                         # unique by Hub adding the Hub user ID to it.

      if ( user.nil? )
        user = User.new
        user.email = email
        user.name  = name
        user.admin = roles.include?( :admin ) || roles.include?( :webmaster )
        user.save!
      end

      @current_user = user
    else
      @current_user = nil
    end

    return @current_user
  end

  # Set the best available locale for the currently logged in user or based
  # on HTTP headers if nobody is logged in right now.
  #
  def set_best_locale
    if ( RAILS_ENV == 'test' )
      code = 'en'
    else
      code = Translation.reconcile_user_data_with_http_request_language(
        request,
        logged_in? ? current_user : nil
      )
    end

    Translation.set_best_locale( code )
  end

  # To use sorting and translatable columns together, we have to reset the
  # sort conditions for translatable models whenever the user's best choice
  # of locale has been set in Rails.
  #
  # For more information, see Jason King's "good_sort" plugin:
  #
  #   http://github.com/JasonKing/good_sort/tree/master
  #
  # ...and Iain Hecker's "translatable_columns" plugin:
  #
  #   http://github.com/iain/translatable_columns/tree/master
  #   http://iain.nl/2008/09/plugin-translatable_columns/
  #
  def set_language_dependent_sorting
    for model in APPCTRL_TRANSLATABLE_MODELS
      model.set_sorting() if model.respond_to?( :set_sorting )
    end
  end

  # Rather annoyingly, ActionMailer templates have no knowledge of the context
  # in which they are invokved, unlike normal view templates. This is strange
  # and, at least for Artisan, unhelpful. We could insist that the system
  # installer configures some static value for the default host for links, but
  # that's a horrible kludge - once the application is running it always knows
  # its host via the "request" object.
  #
  # This filter patches around this Rails hiccup by wasting a few CPU cycles on
  # auto-setup of the e-mail host and protocol.
  #
  def set_email_host_and_protocol
    unless ( ActionMailer::Base.default_url_options.has_key?( :host ) )
      ActionMailer::Base.default_url_options[ :host ] = request.host_with_port
    end

    unless ( ActionMailer::Base.default_url_options.has_key?( :protocol ) )
      ActionMailer::Base.default_url_options[ :protocol ] = request.protocol
    end
  end

  # Run garbage collectors to tidy up resources which expire.
  #
  def run_garbage_collectors
    Donation.garbage_collect( session )
  end
end
