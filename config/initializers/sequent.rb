require_relative '../../db/sequent_migrations'

Sequent.configure do |config|
 config.migrations_class_name = 'SequentMigrations'

 config.command_handlers = [

 ]
  
 config.event_handlers = [

 ]

 config.database_config_directory = 'config'
    
 # this is the location of your sql files for your view_schema
 config.migration_sql_files_directory = 'db/sequent'
end
