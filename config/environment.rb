# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.15' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.autoload_paths += %W( #{RAILS_ROOT}/extras )

  # Mandatory gems
  # ==============
  #
  # Hub:
  #   http://hub.pond.org.uk/
  #   Must be manually installed from the instructions on the site above.
  #
  # Acts As Audited - Rails 2.3.x last stable version is 1.1
  #   https://github.com/collectiveidea/acts_as_audited/tree/1.1-stable
  #   sudo gem install acts_as_audited --version="1.1.0"
  #
  # Faster CSV:
  #   http://fastercsv.rubyforge.org/
  #   http://github.com/JEG2/faster_csv
  #
  # Ya2yaml:
  #   http://github.com/afunai/ya2yaml
  #   http://rubyforge.org/projects/ya2yaml/
  #
  # Locale:
  #   http://www.yotabanana.com/hiki/ruby-locale-rails.html
  #   http://rubyforge.org/projects/locale/
  #
  # Mislav's Will Paginate:
  #   http://github.com/mislav/will_paginate
  #     sudo gem sources -a http://gems.github.com (if you haven't already)
  #     sudo gem install will_paginate
  #
  # Jason King's Good Sort:
  #   http://github.com/JasonKing/good_sort
  #     sudo gem sources -a http://gems.github.com (if you haven't already)
  #     sudo gem install good_sort
  #
  # Geekq's Workflow (similar to Acts As State Machine):
  #   http://github.com/geekq/workflow
  #     sudo gem install workflow
  #
  # Active Merchant:
  #   http://www.activemerchant.org/
  #   sudo gem install activemerchant
  #
  # A recent version of RedCloth:
  #   http://redcloth.org/

  config.gem 'hubssolib',      :version => '>= 0.2.7', :lib => 'hub_sso_lib'
  config.gem 'acts_as_audited',:version =>    '1.1.1'
  config.gem 'fastercsv',      :version => '>= 1.5.3'
  config.gem 'ya2yaml',        :version => '>= 0.30'
  config.gem 'locale',         :version => '>= 2.0.5'
  config.gem 'will_paginate',  :version => '>= 2.3.15'
  config.gem 'good_sort',      :version => '>= 0.2.4'
  config.gem 'workflow',       :version => '>= 0.8.0'
  config.gem 'activemerchant', :version => '>= 1.12.0', :lib => 'active_merchant'
  config.gem 'RedCloth',       :version => '>= 4.2.7'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

# Please also see "environments/*.rb".
