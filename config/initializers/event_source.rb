# frozen_string_literal: true

require 'yaml'

rabbitmq_dev_config = YAML.load_file(File.join(Rails.root, 'config', 'development', 'rabbitmq_config.yml'))

EventSource.configure do |config|
  config.protocols = %w[amqp http]
  config.pub_sub_root = Pathname.pwd.join('app', 'event_source')
  config.server_key = ENV['RAILS_ENV'] || Rails.env.to_sym
  config.app_name = :edi_gateway

  config.servers do |server|
    server.amqp do |rabbitmq|
      rabbitmq.ref = 'amqp://rabbitmq:5672/event_source'
      rabbitmq.host = ENV.fetch('RABBITMQ_HOST', rabbitmq_dev_config['rabbitmq_host'])
      warn rabbitmq.host
      rabbitmq.vhost = ENV.fetch('RABBITMQ_VHOST', rabbitmq_dev_config['rabbitmq_vhost'])
      warn rabbitmq.vhost
      rabbitmq.port = ENV.fetch('RABBITMQ_PORT', rabbitmq_dev_config['rabbitmq_port'])
      warn rabbitmq.port
      rabbitmq.url = ENV.fetch('RABBITMQ_URL', rabbitmq_dev_config['rabbitmq_url'])
      warn rabbitmq.url
      rabbitmq.user_name = ENV.fetch('RABBITMQ_USERNAME', rabbitmq_dev_config['rabbitmq_username'])
      warn rabbitmq.user_name
      rabbitmq.password = ENV.fetch('RABBITMQ_PASSWORD', rabbitmq_dev_config['rabbitmq_password'])
      warn rabbitmq.password
    end
  end

  async_api_resources = ::AcaEntities.async_api_config_find_by_service_name({ protocol: :amqp, service_name: nil }).success
  async_api_resources += ::AcaEntities.async_api_config_find_by_service_name({ protocol: :http, service_name: :enroll }).success

  config.async_api_schemas = async_api_resources.collect { |resource| EventSource.build_async_api_resource(resource) }
end

EventSource.initialize!
