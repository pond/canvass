########################################################################
# File::    canvass_mailer.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Send e-mail messages for important events.
# ----------------------------------------------------------------------
#           21-Feb-2011 (ADH): Created. Based upon Artisan Mailer.
########################################################################

class CanvassMailer < BaseMailer

  helper :application, :currencies

  # Called via deliver_... when wanting to send a new donation confirmation
  # message to a donor. Pass the donation of interest.
  #
  def new_donation_made( donation )
    setup_mail(
      donation.user_email,
      donation,
      :new_donation_made
    )
  end
  
  # Called via deliver_... when wanting to send a new donation notification
  # message to an administrator. Pass the donation of interest.
  #
  def new_donation_made_admin( donation )
    setup_mail(
      ADMINISTRATOR_EMAIL_ADDRESS, # config/initializers/50_general_settings.rb
      donation,
      :new_donation_made_admin
    )
  end

private

  # Configure default email options and render the message template. Pass a
  # recipient e-mail address, data to be passed into the view template under
  # instance variable "@data", the key to look up for the subject line and to
  # use as the base of the template leafname and an optional parameter passed
  # in to the translator when the subject line is looked up - this should be a
  # hash corresponding to the substitution parameters expected by the caller
  # for the message the key passed in the third parameter selects.
  #
  def setup_mail( recipient, data, key, translation_data = {} )
    subject      "[#{ self.class.site_name }] #{ translate( key, translation_data ) }"
    from         NOTIFICATION_EMAILS_COME_FROM # config/initializers/50_general_settings.rb
    recipients   recipient
    sent_on      Time.now
    content_type 'text/plain'
    body         render(
                   :file => "canvass_mailer/#{ key }.txt.erb",
                   :body => { :data => data }
                 )
  end

  # Translate a given key, using that key as the default string. Pass also
  # an optional translation data hash to use for substitutions.
  #
  def translate( key, translation_data = {} )
    I18n.t(
      "uk.org.pond.canvass.canvass_mailer.#{ key }",
      translation_data.merge!( :default => key )
    )
  end
end
