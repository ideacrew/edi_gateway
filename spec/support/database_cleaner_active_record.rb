# frozen_string_literal: true

require 'database_cleaner-active_record'

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner[:active_record].strategy = :transaction }

  # Only truncate the "users" table.
  # DatabaseCleaner[:active_record].strategy = DatabaseCleaner::ActiveRecord::Truncation.new(only: ['users'])

  # Delete all tables except the "users" table.
  # DatabaseCleaner[:active_record].strategy = DatabaseCleaner::ActiveRecord::Deletion.new(except: ['users'])

  config.around(:each) { |example| DatabaseCleaner[:active_record].cleaning { example.run } }
end
