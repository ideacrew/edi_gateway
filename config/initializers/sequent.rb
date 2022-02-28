require_relative '../../db/sequent_migrations'
require_relative '../../sequent/policies'
require_relative '../../sequent/invoices'

Sequent.configure do |config|
 config.migrations_class_name = 'SequentMigrations'

 config.command_handlers = [
   ::Policies::CommandHandler.new,
   ::Invoices::CommandHandler.new
 ]

 config.event_handlers = [
   ::Policies::Projector.new,
   ::Invoices::Projector.new,
   ::Invoices::EventHandler.new
 ]

 config.database_config_directory = 'config'
    
 # this is the location of your sql files for your view_schema
 config.migration_sql_files_directory = 'db/sequent'
end
