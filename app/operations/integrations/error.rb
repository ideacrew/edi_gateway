# frozen_string_literal: true

module Integrations
  # Captures all the exceptions occurred during the process
  class Error
    attr_reader :errors

    def initialize
      @errors = []
      @errors_by_identifier = {}
    end

    def capture_exception
      yield
    rescue StandardError => e
      @errors << e.to_s
    end

    def capture_exception_with(identifier)
      yield
    rescue StandardError => e
      (@errors_by_identifier[identifier] ||= []) << e.to_s
    end

    def errored_on?(identifier)
      @errors_by_identifier.key?(identifier)
    end

    def errors_found?
      @errors.present? || @errors_by_identifier.present?
    end

    def error_messages
      (@errors + @errors_by_identifier.values).flatten
    end
  end
end
