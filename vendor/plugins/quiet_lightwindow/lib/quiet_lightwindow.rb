# QuietLightwindow

module QuietLightwindow
  mattr_accessor :default_options

  # Define the "uses_lightwindow" controller method.
  #
  module ClassMethods
    def uses_lightwindow( filter_options = {} )

      # Work in conjunction with Quiet Prototype if present, so that multiple
      # quiet_... plugins can work together without potentially each including
      # prototype independently, so it ends up included over and over again.
      #
      # If you want to use Lightwindow and Prototype for different sets of
      # actions, call uses_lightwindow first, then uses_prototype, specifying
      # a union of the actions required for both Lightwindow and Prototype in
      # that second call.

      have_quiet_prototype = respond_to?( :uses_prototype )
      uses_prototype( filter_options ) if ( have_quiet_prototype )

      proc = Proc.new do | c |
        c.instance_variable_set( :@uses_lightwindow,     true )
        c.instance_variable_set( :@have_quiet_prototype, true )
      end

      before_filter( proc, filter_options )
    end
  end

  # Add in the class methods and establish the helper calls when the module
  # gets included.
  #
  def self.included( base )
    base.extend( ClassMethods  )
    base.helper( QuietLightwindowHelper )
  end

  # The helper module - methods for use within views.
  #
  module QuietLightwindowHelper

    # Include Lightwindow only if used for the current view, according to the
    # Controller. Invoke using "<%= include_quiet_lightwindow_if_used -%>" from
    # within the HEAD section of an XHTML view. If you want your HTML output
    # to be nice and tidy in terms of indentation :-) then pass a string in
    # the optional parameter - it will be inserted before each "<script>" tag
    # in the returned HTML fragment.
    #
    # If using Quiet Prototype, then this plugin is called to include the
    # Prototype library which Lightwindow requires. Your layout must use the
    # "<%= include_prototype_if_used %>" directive or an equivalent *before*
    # it includes Lightwindow.
    #
    # Note that a trailing newline *is* output so you can call the helper with
    # the "-%>" closing ERB tag (as shown in the previous paragraph) to avoid
    # inserting a single blank line into your output in the event that the
    # plugin is *not* used by the current view.
    #
    def include_lightwindow_if_used( line_prefix = '' )
      return unless using_quiet_lightwindow?

      close      = 'Close'
      loading_or = 'Loading or'
      cancel     = 'cancel'

      if ( defined?( I18n ) )
        close      = I18n.translate( :'pond.quiet_lightwindow.close',      :default => close      )
        loading_or = I18n.translate( :'pond.quiet_lightwindow.loading_or', :default => loading_or )
        cancel     = I18n.translate( :'pond.quiet_lightwindow.cancel',     :default => cancel     )
      end

      script = <<JAVASCRIPT
  var lightwindow_i18n = {
    close:      "#{ ERB::Util.j( close      ) }",
    loading_or: "#{ ERB::Util.j( loading_or ) }",
    cancel:     "#{ ERB::Util.j( cancel     ) }"
  }
JAVASCRIPT

      data = javascript_tag( script.chop )
      data << "\n" << javascript_include_tag( :defaults ) unless have_quiet_prototype?
      data << "\n" << javascript_include_tag( 'lightwindow/lightwindow' )
      data << "\n" << stylesheet_link_tag( 'lightwindow/lightwindow' )

      data.gsub( /^/, line_prefix ) + "\n"
    end

    # Returns 'true' if configured to use the Lightwindow library for the view
    # related to the current request. See the "uses_lightwindow" class method for
    # more information.
    #
    def using_quiet_lightwindow?
      ! @uses_lightwindow.nil?
    end

    # Is "Quiet Prototype" available for including the Prototype library?
    #
    def have_quiet_prototype?
      ! @have_quiet_prototype.nil?
    end
  end
end

# Install the controller and helper methods.

ActionController::Base.send( :include, QuietLightwindow )
ActionView::Base.send :include, QuietLightwindow::QuietLightwindowHelper
