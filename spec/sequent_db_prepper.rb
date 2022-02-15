class SequentDbPrepper

  def prepare
    ensure_event_store
    ensure_view_schemas
    ensure_online_migration
    ensure_offline_migration
  end

  def ensure_event_store
    ensure_rack_env_set!
    db_config = Sequent::Support::Database.read_config(@env)
    create_event_store(db_config)
  end

  def ensure_view_schemas
    ensure_rack_env_set!

    db_config = Sequent::Support::Database.read_config(@env)
    Sequent::Support::Database.establish_connection(db_config)
    Sequent::Migrations::ViewSchema.new(db_config: db_config).create_view_schema_if_not_exists
  end

  def ensure_online_migration
    ensure_rack_env_set!

    db_config = Sequent::Support::Database.read_config(@env)
    view_schema = Sequent::Migrations::ViewSchema.new(db_config: db_config)

    view_schema.migrate_online
  end

  def ensure_offline_migration
    ensure_rack_env_set!

    db_config = Sequent::Support::Database.read_config(@env)
    view_schema = Sequent::Migrations::ViewSchema.new(db_config: db_config)

    view_schema.migrate_offline
  end

  def ensure_rack_env_set!
    ENV['RACK_ENV'] = ENV['RAILS_ENV'] ||= 'test'
    @env ||= ENV['RACK_ENV']
  end

  def create_event_store(db_config)
    event_store_schema = Sequent.configuration.event_store_schema_name
    sequent_schema = File.join(Sequent.configuration.migration_sql_files_directory, "../#{event_store_schema}.rb")
    fail "File #{sequent_schema} does not exist. Check your Sequent configuration." unless File.exists?(sequent_schema)

    Sequent::Support::Database.establish_connection(db_config)
    return nil if Sequent::Support::Database.schema_exists?(event_store_schema)

    Sequent::Support::Database.create_schema(event_store_schema)
    Sequent::Support::Database.with_schema_search_path(event_store_schema, db_config, @env) do
      load(sequent_schema)
    end
  end
end
