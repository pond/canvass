source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

gem 'duktape'
gem 'tzinfo-data'
gem 'hubssolib', '~> 1.0', require: 'hub_sso_lib'
gem 'rails-observers'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use sqlite3 as the database for Active Record
gem 'pg', '= 0.18.4' # TODO: Version lock is a ROOL / RISC OS Open customisation
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use Thin for web server in development
gem 'thin'

# https://github.com/collectiveidea/audited
gem 'audited', '~> 4.7'
# https://github.com/mislav/will_paginate
gem 'will_paginate', '~> 3.1'
# https://github.com/geekq/workflow
gem 'workflow', '~> 2.0'
# https://github.com/activemerchant/active_merchant
gem 'activemerchant', '~> 1.95', require: 'active_merchant'
# http://github.com/jgarber/redcloth
gem 'RedCloth', '~> 4.3'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

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
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end
