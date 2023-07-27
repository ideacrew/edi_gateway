# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.8"

#######################################################
# Local components/engines
#######################################################
gem 'aca_entities', git: 'https://github.com/ideacrew/aca_entities.git', branch: 'trunk'
gem 'aca_x12_entities', git: "https://github.com/ideacrew/aca_x12_entities.git", branch: "trunk"
gem 'event_source', git: 'https://github.com/ideacrew/event_source.git', branch: 'trunk'
# gem 'keycloak',           git: 'https://github.com/ideacrew/keycloak-client.git', branch: 'support_relay_state'
# gem 'keycloak',           git: 'https://github.com/ideacrew/keycloak-client.git', branch: 'trunk'
# gem 'resource_registry',  git:  'https://github.com/ideacrew/resource_registry.git', branch: 'trunk'
# gem 'resource_registry',  path: '../resource_registry'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'

gem 'dry-container',       '0.7.2'
gem 'dry-schema',          '~> 1.6.2'
gem 'dry-types',           '~> 1.5.1'
gem 'dry-validation',      '~> 1.6.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "importmap-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem 'jbuilder'

# Double entry accounting feature [https://github.com/ledermann/keepr]
gem 'keepr', '~> 0.7.0'

# MongoDB Database
gem 'money-rails', '~> 1.15'
gem 'mongoid',             '~> 7.4'

gem 'nokogiri-happymapper'

# Postgres Database
gem 'pg'

# Use Puma as the app server
gem 'puma', '~> 5.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 7.0.0" # , ">= 7.0.0"

gem 'rbnacl'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Use Sass to process CSS
# gem "sassc-rails"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
# gem "sprockets-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'database_cleaner-active_record'
  gem 'database_cleaner-mongoid'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
end

group :development do
  # gem 'listen', '~> 3.3'
  gem 'prettier'
  gem 'redcarpet'
  gem 'rubocop', require: false
  gem 'rubocop-git'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  # gem 'rack-mini-profiler', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console'

  gem 'yard'
  gem 'yard-mongoid'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem 'mongoid-rspec'
  gem "selenium-webdriver"
  gem "webdrivers"
end
