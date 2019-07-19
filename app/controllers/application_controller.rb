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

  # Pagination: https://ddnexus.github.io/pagy/how-to#quick-start
  include Pagy::Backend

  # See ActionController::RequestForgeryProtection for details.
  protect_from_forgery

  # Hub single sign-on support.

  require 'hub_sso_lib'
  include HubSsoLib::Core

  before_action :hubssolib_beforehand
  after_action  :hubssolib_afterwards

  # Other filters

  before_action :assign_real_user
  before_action :set_best_locale
  before_action :set_email_host_and_protocol
  before_action :run_garbage_collectors

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
  # See also before_action-called "assign_real_user()".
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

  # Simplify a lot of work for list views by using Ransack and Pagy to set
  # up search results, sorting and pagination. No explicit AJAX support; use
  # Turbolinks if you want things to be faster than an old school full page
  # request-response cycle.
  #
  # Normal parameters:
  #
  # +model+:: The model to operate upon - e.g. Poll
  #
  # Named parameters:
  #
  # +scope+:: A default scope to base results on - 'model.all' if unset
  #
  def appctrl_search_sort_and_paginate(model, scope: nil)
    scope.inspect
    scope ||= model.all

    @q       = scope.ransack(params[:q])
    @q.sorts = model::DEFAULT_SORT if @q.sorts.empty? && model.const_defined?('DEFAULT_SORT')

    @pagy, @items = pagy(@q.result)

    render()
  end

  # Make sure that "params[ :id ]" retrieves an object where "user_id" is equal
  # to the ID of the current user. If not, an authorisation failure will be
  # forced, unless the current user is an administrator. Usually called as a
  # before_action method for edit-like or destroy-like actions only.
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
      render :file   => File.join( Rails.root, 'public', '404.html' ),
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
    I18n.locale = if ( Rails.env == 'test' )
      'en'
    elsif request.headers.key?('HTTP_ACCEPT_LANGUAGE')
      string = request.headers.fetch('HTTP_ACCEPT_LANGUAGE')
      locale = AcceptLanguage.intersection(string, I18n.default_locale, *I18n.available_locales)
      locale || I18n.default_locale
    else
      I18n.default_locale
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
