########################################################################
# File::    application_helper.rb
# (C)::     Hipposoft 2011
#
# Purpose:: General view utilities for the whole application.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
#           16-Feb-2011 (ADH): Imported lots of code from Artisan.
########################################################################

module ApplicationHelper

  # This has to be a class variable rather than a constant else Rails tends to
  # crash with e.g. "cannot remove Object::APPHELP_BUTTON_MAPPINGS" from a deep
  # backtrace including "cleanup_application", "clear" and
  # "remove_unloadable_constants!".
  #
  # Mappings for button classes and icons under various actions. Bear in mind
  # that a 'show' action is only likely to be used in a button context from an
  # 'edit' form, hence it's cancel-like semantics. The 'index' case is harder
  # as this depends on the context, but is hard-wired to positive semantics
  # here. The user of the hash can modify this by whatever means are most
  # appropriate, if necessary.
  #
  # See "apphelp_protected_button_to" and "apphelp_protected_buttons_to" for
  # examples of use.
  #
  @@apphelp_button_mappings = {

    # For use in a context where the current page represents read-only
    # information (e.g. show/index).

    :for_read_only_pages => {
      :new => {
        :variant => :positive,
        :icon    => :add
      },
      :edit => {
        :variant => :negative,
        :icon    => :edit
      },
      :delete => {
        :variant => :negative,
        :icon    => :delete
      },
      :index => {
        :variant => :standard,
        :icon    => :table
      },
      :show => {
        :variant => :standard,
        :icon    => :show
      }
    },

    # For use in a context where the current page represents a read/write
    # activity (e.g. edit/update).

    :for_read_write_pages => {
      :new => {
        :variant => :positive,
        :icon    => :add
      },
      :edit => {
        :variant => :positive,
        :icon    => :edit
      },
      :index => {
        :variant => :negative,
        :icon    => :cancel
      },
      :show => {
        :variant => :negative,
        :icon    => :cancel
      }
    },

    # General use (not read/write dependent).

    :for_general_use => {

      # Special entries for the log in / sign up pages.

      :login => {
        :variant => :negative,
        :icon    => :account
      },
      :signup => {
        :variant => :negative,
        :icon    => :account
      },

      # Special entry - use this if your action name is not found in the hash.

      :default => {
        :variant => :standard,
        :icon    => :action
      }
    }
  }

  # Return an internationalised version of the web site's name.
  #
  def apphelp_site_name
    t( :'uk.org.pond.canvass.site_name' )
  end
  
  # Return an internationalised version of the web site's tagline if defined,
  # else a blank string.
  #
  def apphelp_site_tagline
    t( :'uk.org.pond.canvass.site_tagline', :default => '' )
  end

  # Return an internationalised version of the given action name. If 'true'
  # is passed in the second parameter, a default fallback of the humanized
  # version of the non-internationalised action name will be chosen. If this
  # parameter is omitted or 'false' is given, the I18n engine's "missing token"
  # message is returned instead (no default string is used).
  #
  def apphelp_action_name( action, use_default = false )
    options = use_default ? { :default => action.to_s.humanize } : {}
    t( "uk.org.pond.canvass.action_names.#{ action }", options )
  end

  # Return an internationalised title appropriate for a page handling the
  # current action for the current controller, or the given controller.
  #
  def apphelp_title( ctrl = controller )
    "#{ apphelp_site_name }: #{ apphelp_heading( ctrl ) }"
  end

  # Return an internationalised heading appropriate for a page handling the
  # current action for the current controller, or the given controller and
  # optional given action name. If you want to use a default string, pass it
  # in the optional third parameter. Headings like this can be (and are) also
  # used as descriptive action link text.
  #
  def apphelp_heading( ctrl = controller, action = nil, default = nil )
    action ||= ctrl.action_name

    t(
      "uk.org.pond.canvass.controllers.#{ ctrl.controller_name }.action_title_#{ action }",
      :default => default
    )
  end

  # Shortcut to avoid long references to "uk.org.pond.canvass.generic_messages"
  # when reading generic messages from the locale file. Pass the message token
  # part (e.g. "yes", "no", "confirmation"). Only useful for basic messages
  # which require no parameter substitution or default lookup values.
  #
  def apphelp_generic( message_name )
    t( "uk.org.pond.canvass.generic_messages.#{ message_name }" )
  end

  # Return an internationalised "are you sure?" confirmation prompt.
  #
  def apphelp_confirm
    heading = apphelp_heading( controller, :delete, '' )
    heading << "\n\n" unless ( heading.empty? )

    return heading + apphelp_generic( :confirmation )
  end

  # Return an internationalised, emphasised "Unknown" quantity message.
  #
  def apphelp_unknown_quantity_warning
    "<em>#{ apphelp_generic( :unknown ) }</em>"
  end

  # Return a controller view hint, based on looking up "view_<foo>" in the
  # locale file for the given value of "<foo>" (as a string or symbol). The
  # controller handling the current request is consulted by default, else
  # pass a reference to the controller of interest in the optional second
  # parameter. If the hint includes subsitution tokens, pass them in an
  # optional third parameter as a hash.
  #
  def apphelp_view_hint( hint_name, ctrl = controller, substitutions = {} )
    t( "uk.org.pond.canvass.controllers.#{ ctrl.controller_name }.view_#{ hint_name }", substitutions )
  end

  # Return 'yes' or 'no', internationalised, according to the given value,
  # which is evaluated as (or should already be) a boolean. Remember that in
  # Ruby the boolean evaluation of certain types can be unexpected - e.g.
  # integer zero is not "nil", so it evaluates to 'true' in a boolean context.
  #
  def apphelp_boolean( bool )
    apphelp_generic( bool ? :yes : :no )
  end

  # Return a piece of text wrapped in a SPAN of class "current_link". Assumes
  # given text is HTML-safe.
  #
  def apphelp_current_link( text )
    "<span class=\"current_link\">#{ text }</span>"
  end

  # Return a view hint (see apphelp_view_hint) based on the given workflow
  # state, by compiling token "view_state_<statename>" and looking it up for
  # the current controller (pass no second parameter) or the given controller
  # (pass this in the second parameter).
  #
  def apphelp_state( state, ctrl = controller )
    apphelp_view_hint( "state_#{ state }", ctrl )
  end

  # Constructs links to controllers and actions based on whether or not users
  # can perform given actions.
  #
  # Pass the action name as a symbol, then two options hashes. The first is
  # used by this function and the second is passed to both a permissions
  # checking method written in the User model and to a Rails URL generation
  # method. The various methods are determined from the first options hash.
  # Things to specify there:
  #
  #   :method - the name of the Rails URL generation method to call, e.g.
  #             "edit_user_url" or "show_language_url".
  #
  #   :url - You should always try to keep things simple and for such cases
  #           ":method" ought to be sufficient for generating a correct URL
  #           for the link. In some cases though the URL generation may be
  #           too complex for the ":method" mechanism to handle, so you can
  #           circumvent it by passing in a URL directly,
  #
  #   :controller - A Controller (e.g. UsersController or LanguagesController)
  #                 from which an ActiveRecord model is inferred (via
  #                 "controller_name.classify.constantize" (thus, e.g.
  #                 'LanguagesController' => 'languages' => 'Language' =>
  #                 model). Permissions methods are invoked on the model. The
  #                 controller name is also used to look up appropriate link
  #                 text in the languages file. If omitted, the controller
  #                 handling the current request is used.
  #
  #   :model - A model (e.g. User or Language) if :controller does not lead
  #            to the model on which to invoke a permissions method.
  #
  #   :short - if 'true', the link text is obtained from apphelp_action_name
  #            which returns short one or two word results. If omitted or
  #            'false', apphelp_heading is used, which returns more
  #            descriptive results. Short versions tend to be useful for
  #            action links in index tables of objects, long versions tend
  #            to be useful e.g. near the footer of other kinds of page.
  #
  #   :class - If present, the value is used for a 'class' attribute on the
  #            link ("<a>" tag), should one be generated.
  #
  #   :title - If present, the value is used for a 'title' attribute on the
  #            link ("<a>" tag), should one be generated.
  #
  #   :bypass - In very rare cases you may wish to use all the facilities of
  #             this generator, but bypass security and assume the link should
  #             definitely be generated. An example is an 'Add to cart' link,
  #             where the relevant controller's action explicitly supports
  #             working when no user is logged in via the redirect-to-sign-in-
  #             or-sign-up-then-add-product dance. In the vast majority of
  #             cases though, you should never set this option to 'true'.
  #
  #   :text   - You can override the visible link text here, or by passing in
  #             a block which evaluates to a string for the link text (see
  #             below for more).
  #
  # In Artisan, the action name is used to construct a method called on the
  # model class, but Canvass' hub-integrated permission model differs. Instead,
  # the action name will be checked against the model's associated controller's
  # permissions table.
  #
  # The permissions method is passed the second options hash as its only
  # input parameter.
  #
  # Should the current user have permission to perform the relevant action
  # under the relevant controller, the Rails URL generator method in :method
  # is invoked. It is also passed the second options hash.
  #
  # Since Rails URL generator methods in newer Rails versions often support
  # being passed a variety of different types, the "options hash" can actually
  # be whatever type is supported by the method named in ":method". So long as
  # both that method and the permissions method in the User object support
  # that data type as an input parameter, everything should work fine.
  #
  # Note that if the second options hash is omitted, it defaults to a value
  # of 'true' - useful for actions which require no URL generator parameters.
  #
  # If you pass a block after the function call, the block will be invoked
  # with no parameters when the link is being generated. The return value is
  # used as link text instead of the internationalised controller and action
  # name composition described above. Alternatively, if you prefer, specify the
  # text using the ":text" link option.
  #
  # For example, in any Home Page view:
  #
  #   <%= apphelp_protected_link_to( :edit, :method => :edit_home_page_url ) %>
  #
  # ...would check HomePagesController for the current user's ability to invoke
  # the 'edit' action link to "edit_home_page_url" with internationalised link
  # text if so.
  #
  def apphelp_protected_link_to( action, options_for_link, options_for_url = nil )
    ctrl   =   options_for_link[ :controller ] || controller.class
    bypass =   options_for_link[ :bypass     ]
    model  = ( options_for_link[ :model      ] || ctrl.controller_name.classify.constantize ) unless bypass
    clsnm  =   options_for_link[ :class      ]
    title  =   options_for_link[ :title      ]
    trans  =   options_for_link[ :text       ]

    permission = bypass || get_permission( model, action, options_for_url )
    return permission unless permission == true

    # For the link text, we try to find the "action_title_<action_name>" string
    # for the given controller, but if that fails fall back to the basic list
    # of translated action names, or just quote the name without translation.

    if ( options_for_link.has_key?( :url ) )
      url = options_for_link.delete( :url )
    else
      url = send( options_for_link[ :method ], options_for_url )
    end

    if ( trans.nil? )
      if ( block_given? )
        trans = yield()
      elsif ( options_for_link[ :short ] )
        trans = apphelp_action_name( action, true )
      else
        trans = apphelp_heading(
          ctrl,
          action,
          apphelp_action_name( action, true )
        )
      end
    end

    return link_to( trans, url, :class => clsnm, :title => title )
  end

  # Writes numerous protected links via apphelp_protected_link_to. See that
  # method for details. Pass a separator string to output in between any two
  # consecutive links (including white space if desired) and then a series of
  # arrays. Each array lists parameters, in order, to be passed to
  # apphelp_protected_link_to.
  #
  # For example, the Users controller's "show" view might want to offer links
  # to edit the shown account or list all accounts. An agent may be able to
  # show details of other users' accounts but not edit them. A client will be
  # able to show and edit their own account, but not list other accounts. An
  # administrator can always do both. In the show.html.erb file describing a
  # user object stored in "@user", we might add:
  #
  #   <%=
  #     apphelp_protected_link_to(
  #       ' | ',
  #       [ :edit,  { :method => :edit_user_path }, @user ],
  #       [ :index, { :method => :users_path     }        ]
  #     )
  #   %>
  #
  # This will produce conditional "edit" and "index" links with " | " text
  # separating them, if both are present (else no separator text is shown).
  #
  # To help cases where you may want entire links to be present or absent due
  # to some external factor (e.g. a "show profile" link for users with a
  # profile should be omitted for users without), parameters may be 'nil'. Any
  # such parameter entries are simply ignored.
  #
  # As a special extension the separator string can be replaced by an options
  # hash currently accepting these keys:
  #
  #   :prefix => String to insert at start of each line if line is not empty
  #   :suffix => String to add to end of each line if line is not empty
  #
  # For example, you may choose to use a prefix option of "<li>" and suffix of
  # "</li>" to wrap each link in a list item container.
  #
  def apphelp_protected_links_to( separator, *link_data )
    links = ''

    if ( separator.is_a?( Hash ) )
      options   = separator
      separator = ''
    else
      options = {}
    end

    link_data.each do | data |
      next if data.nil?

      link = apphelp_protected_link_to( data[ 0 ], data[ 1 ], data[ 2 ] )

      # If the call generates link text, add it. Except for the very first
      # added link (when 'links' is empty), always add a separator.

      unless link.empty?
        links << separator unless ( links.empty? )
        links << ( options[ :prefix ] || '' )
        links << link
        links << ( options[ :suffix ] || '' )
      end
    end

    return links
  end

  # A simple version of "apphelp_protected_link_to". Pass a model object
  # instance and the display text to use to represent that instance as part
  # of a "show" link, to show details of the object. If the current user has
  # permission to view the object a link will be returned, else just a plain
  # piece of the given text is returned. HTML safety is ensured.
  #
  # If the first parameter is "nil", the return value of a call to
  # "apphelp_unknown_quantity_warning" is returned instead.
  #
  # If the second parameter is omitted, a special case of using the object's
  # "name" method to retrieve the display text applies - this is a very common
  # case for callers.
  #
  def apphelp_protected_show_link( obj, name = nil )
    return apphelp_unknown_quantity_warning() if ( obj.nil? )

    name = obj.name if ( name.nil? )
    link = apphelp_protected_link_to(
      :show,
      {
        :model  => obj.class,
        :method => :url_for
      },
      obj
    ) { h( name ) }

    return ( link.empty? ) ? h( name ) : link
  end

  # Works as "apphelp_protected_link_to". In this case, though, the code calls
  # through to "apphelp_protected_buttons_to" (rather than the other way around
  # as for the "_link[s]_" methods), so see that method for more information,.
  #
  def apphelp_protected_button_to( action, options_for_link, options_for_url = nil )
    apphelp_protected_buttons_to(
      [ action, options_for_link, options_for_url ]
    )
  end

  # Works as "apphelp_protected_links_to", but writes links in the style of
  # buttons (assuming supporting CSS). You will usually want to wrap the output
  # in a container DIV of class "buttons"; this is not done automatically in
  # case you want to add other things inside the same container (such as a
  # 'real' form submission button). See:
  #
  #   http://particletree.com/features/rediscovering-the-button-element/
  #
  # Method "apphelp_protected_links_to" takes a separator string followed by
  # arrays of up to three entries which are used as parameters for method
  # "apphelp_protected_link_to". This method has no separator string but takes
  # the same kind of array.
  #
  # In the second entry in each array (the link options hash) there are some
  # additional keys you can specify:
  #
  #   :variant => a class name used for the link
  #   :icon    => an icon name used for the link (e.g. "add" for "add.png") -
  #               drawn from "/images/icons/" automatically
  #   :text    => text to use for the link, else 'apphelp_heading' is called
  #
  # The variant and icon will be automatically determined from the action name
  # given in the first array entry via @@apphelp_button_mappings falling to the
  # @@apphelp_button_mappings[ :default ] entry if the action is not found. You
  # can use the link options hash's ":variant" and/or ":icon" keys to override
  # this if necessary.
  #
  # A class name from APPHELP_BUTTON_MAPPINGS or ":variant" is assigned to the
  # actual link tag, along with class name "round" (e.g. "positive round"). If
  # you want to override this, specify the ":class" key in the link options.
  #
  def apphelp_protected_buttons_to( *button_data )
    buttons = ''

    button_data.each do | data |
      next if ( data.nil? )

      action           = data[ 0 ] # NB: This is the action the button will represent, not the current, user-requested action for the enclosing page.
      options_for_link = data[ 1 ] || {}
      options_for_url  = data[ 2 ]

      case action_name.to_sym # NB: This is the current, user-requested action for the enclosing page, not the action the button will represent.
        when :new, :create, :edit, :update
          mapping_hash = @@apphelp_button_mappings[ :for_read_write_pages ]
        when :show, :index
          mapping_hash = @@apphelp_button_mappings[ :for_read_only_pages  ]
        else
          mapping_hash = @@apphelp_button_mappings[ :for_general_use      ]
      end

      mapping = mapping_hash[ action ] || @@apphelp_button_mappings[ :for_general_use ][ :default ]
      ctrl    = options_for_link[ :controller ] || controller.class
      variant = options_for_link.delete( :variant ) || mapping[ :variant ]
      icon    = options_for_link.delete( :icon    ) || mapping[ :icon    ]
      text    = options_for_link.delete( :text    ) || apphelp_heading( ctrl, action )

      options_for_link[ :class ] ||= "#{ variant } round"

      buttons += ' ' unless ( buttons.empty? )
      buttons += apphelp_protected_link_to(
                   action,
                   options_for_link,
                   options_for_url
                 ) do
                   image_tag(
                     "icons/#{ icon }.png",
                     :alt => '' # Explicit empty ALT text => icon not important for screen reading
                   ) << text
                 end
    end

    return buttons
  end

  # Generate a submit BUTTON with name "submit_changes" and a more traditional
  # INPUT TYPE="submit" with name "msie6_commit_changes" wrapped in conditional
  # comments, in the context of the given form, using text based on the given
  # action name (as a symbol), the generated HTML indented by the optional
  # prefix string given in the third parameter.
  #
  # The second parameter can be a string rather than an action name given as a
  # symbol. If a symbol, button text is found via "apphelp_action_name". If a
  # string, the value is used directly.
  #
  # If the first parameter (form) is 'nil', then a context-less 'submit_tag'
  # call will be used for the 'INPUT TYPE="submit"' button, rather than calling
  # the 'submit' method on the given form object.
  #
  def apphelp_submit( form, action_or_string, indent = nil )
    return apphelp_complex_button(
             form,
             action_or_string,
             {
               :indent       => indent,
               :button_image => 'accept'
             }
           )
  end

  # A more complex version of 'apphelp_submit' which is used for more general
  # buttons. Pass the form and action parameters as for 'apphelp_submit' then
  # an options hash:
  #
  #   Key          Value meaning
  #   ==========   ============================================================
  #   indent        Optional indent string, used as a prefix on each line of
  #                 output.
  #   input_class   Class name for INPUT tag; default is "obvious" if omitted.
  #   input_name    Name for INPUT tag; default is "msie6_commit_changes".
  #   button_class  Class name for BUTTON tag; always has "round" added;
  #                 default is "positive".
  #   button_name   Name for BUTTON tag; default is "commit_changes".
  #   button_image  Image leaf, e.g. "add" for "icons/add.png"
  #                 - if omitted, no image is used within the BUTTON container.
  #   confirm       Confirmation text, if you want JavaScript confirmation.
  #
  def apphelp_complex_button( form, action_or_string, options = {} )

    # Process the various input arguments and options.

    if ( form.nil? )
      obj    = self
      method = :submit_tag
    else
      obj    = form
      method = :submit
    end

    if ( action_or_string.is_a?( Symbol ) )
      action_or_string = apphelp_action_name( action_or_string )
    end

    indent       = options.delete( :indent       )
    input_name   = options.delete( :input_name   ) || 'msie6_commit_changes'
    input_class  = options.delete( :input_class  ) || 'obvious'
    button_name  = options.delete( :button_name  ) || 'commit_changes'
    button_class = options.delete( :button_class ) || 'positive'
    button_image = options.delete( :button_image )
    confirm      = options.delete( :confirm      )

    if ( button_class.empty? )
      button_class  = 'round'
    else
      button_class << ' round'
    end

    if ( button_image.nil? )
      button_html = ''
    else
      button_html = "  #{ image_tag( 'icons/' + button_image + '.png', :alt => '' ) }\n"
    end

    if ( confirm.nil? )
      confirm_data = nil
      confirm_html = ''
    else
      confirm      = j( confirm ).gsub( "\n", "\\n" );
      confirm_data = "return confirm(&quot;#{ confirm }&quot;)"
      confirm_html = " onclick=\"#{ confirm_data }\";"
    end

    # Create the HTML string.

    html = <<HTML
<!--[if IE 6]>
#{ obj.send( method, action_or_string, { :class => input_class, :name => input_name, :onclick => confirm_data } ) }
<div style="display: none;">
<![endif]-->
<button type="submit" class="#{ button_class }" id="#{ button_name }" name="#{ button_name }"#{ confirm_html }>
#{ button_html }  #{ action_or_string }
</button>
<!--[if IE 6]>
</div>
<![endif]-->
HTML

    # Indent and return the data.

    html.gsub!( /^/, indent ) unless ( indent.nil? || indent.empty? ) # Not 'indent.blank?', as this would ignore all-white-space strings
    return html
  end

  # Return a form containing a button with JS deletion confirmation, which
  # if activated will delete the given object. Works on the same principles
  # as apphelp_protected_link_to but everything runs from the controller
  # handling the current request. so its name is used to get a Model and a
  # "can_destroy?" method is invoked on it or, if that is missing, a
  # "can_modify?" method is invoked. Special case: A current user MUST be
  # logged in.
  #
  # The function returns an empty string if there is no current user or if
  # one of the permissions methods returns 'false'. The function returns an
  # empty string in production mode or warning string in development mode if
  # both methods are missing.
  #
  # The input parameter gets passed through to button_to's second parameter,
  # so you can use any url_for() parameters here, including specifying a URL
  # directly if you have unusual requirements, or just passing in an
  # ActiveRecord model object instance reference for simple cases.
  #
  # For a long button name, pass "true" in the optional second parameter -
  # else a short version is used based only on the action name.
  #
  def apphelp_protected_delete_button( obj, short = true )
    model      = controller.controller_name.classify.constantize
    permission = get_permission( model, :destroy, obj )

    if ( permission == true )
      button_text = apphelp_action_name( :destroy )
      button_text = apphelp_heading( controller, :delete, button_text ) unless ( short )

      return button_to(
               button_text,
               obj,
               {
                 :confirm => apphelp_confirm(),
                 :method  => :delete
               }
             )
    else
      return permission
    end
  end

  # Return a small table containing action links / buttons for a row in an
  # index table. Pass a string (not symbol) to use to construct helper method
  # names for URLs for the links (e.g. "language" to use "language_path" for a
  # 'show' action link and "edit_language_path" for an 'edit' action link) and
  # the Active Record object for which the links / buttons are being generated.
  #
  # If an optional third parameter is provided, it is assumed to be a user ID -
  # usually an owner of the given object - and this ID is used for RESTful
  # user-based editing instead of context free editing. That is, rather than
  # generating a link based on "edit_foo_path", "edit_user_foo_path" will be
  # called instead.
  #
  # As a special case you can actually pass a model instance instead of a user
  # ID in the user ID field. This will be turned into a name and used for the
  # resourceful URL; e.g. pass a Currency instance for "currency_..." paths.
  #
  def apphelp_index_actions( name, obj, user_id_or_obj = nil )

    if ( user_id_or_obj.nil? )
      show_method =      "#{ name }_path"
      edit_method = "edit_#{ name }_path"
      arg         = obj
    elsif ( user_id_or_obj.is_a?( String ) || user_id_or_obj.is_a?( Fixnum ) )
      show_method =      "user_#{ name }_path"
      edit_method = "edit_user_#{ name }_path"
      arg         = { :id => obj.id, :user_id => user_id_or_obj }
    else
      resname     = user_id_or_obj.class.table_name.singularize
      show_method =      "#{ resname }_#{ name }_path"
      edit_method = "edit_#{ resname }_#{ name }_path"
      arg         = { :id => obj.id }
      arg[ "#{ resname }_id".to_sym ] = user_id_or_obj.id
    end

    show = apphelp_protected_link_to( :show, { :short => true, :method => show_method }, arg )
    edit = apphelp_protected_link_to( :edit, { :short => true, :method => edit_method }, arg )

    if ( respond_to? "delete_#{ name }_path" )
      dsty = apphelp_protected_link_to( :delete, { :short => true, :method =>  "delete_#{ name }_path" }, obj )
    else
      dsty = apphelp_protected_delete_button( obj )
    end

    result = "<table class=\"no_border\" border=\"0\"><tr>"

    result << '<td>' << show << '</td>' unless ( show.empty? )
    result << '<td>' << edit << '</td>' unless ( edit.empty? )
    result << '<td>' << dsty << '</td>' unless ( dsty.empty? )

    return result << "</tr></table>"
  end

  # As will_paginate, but uses internationalised next/previous link text and
  # sets a few common preferred preferences in passing.
  #
  def apphelp_i18n_will_paginate( what )
    will_paginate(
      what,
      :previous_label => t( :'uk.org.pond.canvass.pagination.previous' ),
      :next_label     => t( :'uk.org.pond.canvass.pagination.next'     )
    )
  end

  # Return the result of 'select_tag' / 'form.select' for a list of values
  # given in the first parameter, to set a form field (and thus params hash
  # entry) with an ID determined by the second parameter, according to options
  # given the optional third parameter.
  #
  # The values in the first parameter are specified as an array. Each array
  # entry is itself another array with a pair of entries - the first gives the
  # menu text to show in the selection menu and the second gives the associated
  # value to store if the menu entry is selected (often a database object ID),
  # e.g.:
  #
  #   [
  #     [ "Cambridge", "16" ], # Menu text "Cambridge", form field value "16"
  #     [ "London",    "15" ],
  #     [ "UK",        "4"  ],
  #   ]
  #
  # Values are made HTML-safe by Rails in passing, so don't do this as the
  # caller, else you will see double escaping problems.
  #
  # The other parameters vary according to the two main ways this method should
  # be used:
  #
  # (1) To fill in a field of an object which is being created or edited,
  #     in which case view code along the lines of
  #     "form_for <object> do | form |" is in use.
  #
  # (2) To generate a stand-alone menu which will reflect the result of the
  #     menu selection in a form field accessible via the "params" hash.
  #
  # In case (1), the options hash must contain key ":form" with a value of the
  # form being created (the 'form' in "do | form |" above). The menu is built
  # by calling "form.select(...)". The 'method' parameter is the method name
  # (or property name) of the object that is being updated, for example, a list
  # of languages associated with a location might be generated in which case
  # the location's ":language_id" method name would be specified, since this is
  # the name of the accessor method for the property that must be filled in.
  #
  # If the options hash is not given or contains no ":form" key, use case (2)
  # will apply.
  #
  # In case (2), the options hash may contain key ":selected" which contains a
  # value indicating what should be initially selected in the menu. This must
  # match one of the second entries in the two-entry arrays used for the wider
  # array of menu values (so "16", "15" or "4" in the example above). If there
  # is no match results are undefined. If you specify no ":selected" key then
  # the first item in the values array is used as default instead. In addition,
  # the second input parameter names the key that will be set in the "params"
  # hash containing the selected value (via an appropriately named form field
  # in the returned HTML data).
  #
  # Other options values:
  #
  #   :include_blank => An array containing an item to push in as an extra
  #                     menu value: [<menu text>, <value to submit with form>].
  #
  # Any remaining options are passed to select_tag or form.select as HTML
  # options, so you can do things like, for example, ":onchange => 'foo()'" to
  # have JavaScript function 'foo' execute when a menu selection is made.
  #
  def apphelp_menu( values, method, options = {} )
    form = options.delete( :form )
    vals = values.dup # Don't alter passed-by-reference array from caller
    vals.unshift( options.delete( :include_blank ) ) if ( options.has_key?( :include_blank ) )

    if ( form.nil? )
      return select_tag(
        method,
        options_for_select(
          vals,
          options.delete( :selected ) || vals[ 0 ][ 1 ]
        ),
        options
      )
    else
      return form.select( method, vals, {}, options )
    end
  end

private # Meaningless in a module - just put here as a separator...

  # NOTE UNUSUAL RETURN VALUE. This function is inherited from Artisan but
  # rewritten for the Hub permissions model.
  #
  # Pass a model in the first parameter - a Controller name is derived from
  # this (e.g. User => UsersController, Poll => PollsController). Pass an
  # action in the second and either a hash containing a "user_id" key, or 'nil'
  # to get permissions for the currently logged in user.
  #
  # Returns an empty string if the user is NOT permitted to perform that action
  # according to the controller derived from the given model. Returns 'true' if
  # the user IS permitted to perform the action.
  #
  # Summary - returns a string if permission is denied, else 'true'.
  #
  def get_permission( model, action, options_for_permission )

    # Note 'ctrl' will be set to the *class*, not an instance. The exception
    # handler block lets us handle "ModelsController" in the common pluralized
    # case, then try "ModelController" in the unusual singleton resource case,
    # then drop out with 'nil' if something goes wrong.

    ctrl = begin
      "#{ model.name.pluralize }Controller".constantize
    rescue
      "#{ model.name           }Controller".constantize
    end

    return true unless ctrl.nil? == false && ctrl.respond_to?( :hubssolib_permissions )

    # From-Artisan backwards compatibility: Options should be a User, but we
    # allow a hash with user_id too.

    if ( options_for_permission.is_a? Hash )
      user = User.find_by_id( options_for_permission[ :user_id ] )
    elsif ( logged_in? )
      user = controller.current_user() # (sic. - query current action's controller *instance* for current user)
    else
      user = nil
    end

    roles       = HubSsoLib::Roles.new( user.nil? ? false : user.admin )
    permissions = ctrl.hubssolib_permissions()

    roles.clear if ( user.nil? )

    return permissions.permitted?( roles, action ) == true ? true : ''
  end
end
