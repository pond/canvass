########################################################################
# File::    quiet_leightbox.rb
# (C)::     Hipposoft 2009
#
# Purpose:: Only include Leightbox components if a view requires them.
# ----------------------------------------------------------------------
#           16-Nov-2009 (ADH): Created.
########################################################################

module QuietLeightbox
  mattr_accessor :default_options

  # Define the "uses_leightbox" controller method.
  #
  module ClassMethods
    def uses_leightbox( filter_options = {} )

      # Work in conjunction with Quiet Prototype if present, so that multiple
      # quiet_... plugins can work together without potentially each including
      # prototype independently, so it ends up included over and over again.
      #
      # If you want to use Leightbox and Prototype for different sets of
      # actions, call uses_leightbox first, then uses_prototype, specifying
      # a union of the actions required for both Leightbox and Prototype in
      # that second call.

      have_quiet_prototype = respond_to?( :uses_prototype )
      uses_prototype( filter_options ) if ( have_quiet_prototype )

      proc = Proc.new do | c |
        c.instance_variable_set( :@uses_leightbox,       true )
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
    base.helper( QuietLeightboxHelper )
  end

  # The helper module - methods for use within views.
  #
  module QuietLeightboxHelper

    # Include Leightbox only if used for the current view, according to the
    # Controller. Invoke using "<%= include_quiet_leightbox_if_used -%>" from
    # within the HEAD section of an XHTML view. If you want your HTML output
    # to be nice and tidy in terms of indentation :-) then pass a string in
    # the optional parameter - it will be inserted before each "<script>" tag
    # in the returned HTML fragment.
    #
    # If using Quiet Prototype, then this plugin is called to include the
    # Prototype library which Leightbox requires. Your layout must use the
    # "<%= include_prototype_if_used %>" directive or an equivalent *before*
    # it includes Leightbox.
    #
    # Note that a trailing newline *is* output so you can call the helper with
    # the "-%>" closing ERB tag (as shown in the previous paragraph) to avoid
    # inserting a single blank line into your output in the event that the
    # plugin is *not* used by the current view.
    #
    def include_leightbox_if_used( line_prefix = '' )
      return unless using_quiet_leightbox?

      if have_quiet_prototype?
        data = ""
      else
        data = javascript_include_tag( :defaults ) << "\n"
      end

      data         << javascript_include_tag( 'leightbox/leightbox' )
      data << "\n" << stylesheet_link_tag( 'leightbox/leightbox' )

      data.gsub( /^/, line_prefix ) + "\n"
    end

    # Returns 'true' if configured to use the Leightbox library for the view
    # related to the current request. See the "uses_leightbox" class method for
    # more information.
    #
    def using_quiet_leightbox?
      ! @uses_leightbox.nil?
    end

    # Is "Quiet Prototype" available for including the Prototype library?
    #
    def have_quiet_prototype?
      ! @have_quiet_prototype.nil?
    end
  end
end

# Install the controller and helper methods.

ActionController::Base.send( :include, QuietLeightbox )
ActionView::Base.send :include, QuietLeightbox::QuietLeightboxHelper
