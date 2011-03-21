########################################################################
# File::    help_helper.rb
# (C)::     Hipposoft 2010
#
# Purpose:: Utility methods for views providing help text.
# ----------------------------------------------------------------------
#           15-Jan-2010 (ADH): Created.
#           18-Feb-2011 (ADH): Imported from Artisan.
########################################################################

module HelpHelper

  # Pass the name of a help view parial, e.g. "user_geography" or
  # "attach_video". Returns HTML consisting of an image linked to the
  # associated help page in a blank target window.
  #
  def help_link( partial )
    help_url( help_path( partial ) )
  end

  # Pass a URL. Returns HTML consisting of an image linked to the given URL
  # on the assumption that this URL is for some kind of help page.
  #
  def help_url( url )
    link_to(
      image_tag(
        'icons/help.png',
        :size  => '16x16',
        :alt   => '?',
        :align => 'top',
        :class => 'help'
      ),
      url,
      :target => '_blank',
      :class  => 'help'
    )
  end
end
