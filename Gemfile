# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'aca_entities', git:  'https://github.com/ideacrew/aca_entities.git', branch: 'create_user_fee_model_181271601'
gem 'aca_x12_entities', git: "https://github.com/ideacrew/aca_x12_entities.git", branch: "trunk"

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'

gem 'dry-matcher',          '~> 0.8'
gem 'dry-monads',           '~> 1.3'
gem 'dry-schema'
gem 'dry-struct',           '~> 1.3'
gem 'dry-transaction'
gem 'dry-types',            '~> 1.4'
gem 'dry-validation',       '~> 1.6'

gem 'event_source',  git:  'https://github.com/ideacrew/event_source.git', branch: 'trunk'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

# gem 'keepr', path: 'vendor/plugins/keepr'
gem 'keepr', '~> 0.7.0'

# MongoDB Database
gem 'mongoid',             '~> 7.3.1'

gem 'nokogiri-happymapper'

# Postgres Database
gem 'pg'

# Use Puma as the app server
gem 'puma', '~> 5.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.3', '>= 6.1.3.1'

# gem 'resource_registry',  git:  'https://github.com/ideacrew/resource_registry.git', branch: 'trunk'

gem 'rbnacl'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'

group :development, :test do
  gem 'database_cleaner-active_record'
  gem 'database_cleaner-mongoid'
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'rspec-rails',            '~> 5.0'
  gem 'shoulda-matchers',       '~> 3'
  gem 'yard'
  gem 'yard-mongoid'
end

group :development do
  gem 'listen', '~> 3.3'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'

  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
end

