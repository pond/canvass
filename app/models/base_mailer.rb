########################################################################
# File::    base_mailer.rb
# (C)::     Hipposoft 2010
#
# Purpose:: Support classes which send e-mail messages.
# ----------------------------------------------------------------------
#           22-May-2010 (ADH): Created.
#           21-Feb-2011 (ADH): Imported from Artisan.
########################################################################

class BaseMailer < ::ActionMailer::Base

  # In Artisan, notification messages are sent as plain text. The line width
  # used for word wrap is set below. It should never exceed 80 as this may
  # make it difficult to view the message with some e-mail clients.
  #
  EMAIL_PLAIN_TEXT_LINE_WIDTH = 70

  # Some of the views require apphelp_site_name(), but we can't risk including
  # the Application Helper as it might collide with bits of Devise for the
  # DeviseMailer sub-class. In addition, the site name is used for subject
  # lines in all messages, so we need the helper method from the models too.
  # This method provides a simple way to get at the site name.
  #
  def self.site_name
    I18n.t( :'uk.org.pond.canvass.site_name' )
  end

  # Return a translated string formatted according to e-mail text width
  # restrictions. The "key" parameter is the leaf key to use in the locale
  # file (e.g. "foo" gives "uk.org.pond.canvass.canvass_mailer.foo" if called
  # via the ArtisanMailer class). Pass a translation substitution hash in the
  # optional second parameter.
  #
  def self.formatted( key, translation_data = {} )
    # The strange 'extend' stuff is a way of calling through to a helper.
    Object.new.extend( ActionView::Helpers::TextHelper ).word_wrap(
      I18n.t(
        "uk.org.pond.canvass.#{ self.name.tableize.singularize }.#{ key }",
        translation_data.merge!( :default => key )
      ),
      :line_width => EMAIL_PLAIN_TEXT_LINE_WIDTH
    )
  end
end
