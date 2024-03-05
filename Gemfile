# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

#######################################################
# Local components/engines
#######################################################
gem 'aca_entities', git: 'https://github.com/ideacrew/aca_entities.git', branch: 'trunk'
gem 'aca_x12_entities', git: "https://github.com/ideacrew/aca_x12_entities.git", branch: "trunk"
gem 'event_source', git: 'https://github.com/ideacrew/event_source.git', branch: 'trunk'
gem 'resource_registry', git: 'https://github.com/ideacrew/resource_registry.git', branch: 'trunk'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem 'carrierwave-mongoid','~> 1.4.0', :require => 'carrierwave/mongoid'

gem 'dry-container',       '0.11.0'
gem 'dry-schema',          '1.11.3'
gem 'dry-types',           '1.6.1'
gem 'dry-validation',      '1.9.0'

# Double entry accounting feature [https://github.com/ledermann/keepr]
gem 'keepr', '~> 0.7.0'

# MongoDB Database
gem 'money-rails', '~> 1.15'
gem 'mongoid',             '~> 7.4'

gem 'nokogiri', '~> 1.16.2'
gem 'nokogiri-happymapper'

# Postgres Database
gem 'pg'

# Use Puma as the app server
gem 'puma', '~> 6.4.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.0.8.1'

gem 'rbnacl'

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

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console'

  gem 'yard', '~> 0.9.35'
  gem 'yard-mongoid'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem 'mongoid-rspec'
  gem "selenium-webdriver"
  gem "webdrivers"
end
