source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'duktape'
gem 'tzinfo-data'
gem 'hubssolib', '~> 2.1', require: 'hub_sso_lib'
gem 'rails-observers'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'
# Use sqlite3 as the database for Active Record
gem 'pg', '~> 1.4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use Thin for web server in development
gem 'thin'
# assistance for "AcceptLanguage" HTTP header processing:
# https://github.com/cyril/accept_language.rb
gem 'accept_language', '~> 1.0'

# Remember who changed what, when:
# https://github.com/collectiveidea/audited
gem 'audited', '~> 4.7'
# Fast pagination:
# https://github.com/ddnexus/pagy
gem 'pagy', '~> 3.3'
# Searching and sorting:
# https://github.com/activerecord-hackery/ransack
gem 'ransack', '~> 2.1'
# Model state machines:
# https://github.com/geekq/workflow
gem 'workflow', '~> 2.0'
gem 'workflow-activerecord', '>= 4.1'
# Money gem, mostly for string formatting:
#https://rubygems.org/gems/money
gem 'money', '~> 6.16'
# PayPal support:
# https://rubygems.org/gems/paypal-checkout-sdk
gem 'paypal-checkout-sdk', '~> 1.0'
# Textile (Canvass predates the wider popularity of Markdown):
# http://github.com/jgarber/redcloth
gem 'RedCloth', '~> 4.3'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'

  # https://github.com/yamldb/yaml_db
  gem 'yaml_db', '~> 0.7'
end

group :test do

  # Adds support for Capybara system testing and selenium driver, headless:
  # https://rubygems.org/gems/capybara
  # https://rubygems.org/gems/capybara-screenshot
  #
  gem 'capybara', '~> 3.26'
  gem 'capybara-screenshot', '~> 1.0'

  # Easy installation and use of chromedriver to run system tests with Chrome:
  # https://rubygems.org/gems/webdrivers
  #
  gem 'webdrivers', '~> 4.1'

end
