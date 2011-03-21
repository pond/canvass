# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql

# Mandatory gems
# ==============
#
# Lorem (for the bulk product creation script in test/tools)
#   http://github.com/jnunemaker/lorem
#
# Webrat (for tests)
#   http://github.com/brynary/webrat
#
# Launchy (so webrat can send error pages to your web browser)
#   http://copiousfreetime.rubyforge.org/launchy/

config.gem 'lorem',    :version => '>= 0.1.2'
config.gem 'webrat',   :version => '>= 0.7.1'

# Optional gems
# =============
#
# Launchy (so webrat can send error pages to your web browser)
#   http://copiousfreetime.rubyforge.org/launchy/

config.gem 'launchy',  :version => '>= 0.3.5'
