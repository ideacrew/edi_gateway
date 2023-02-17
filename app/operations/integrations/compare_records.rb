# frozen_string_literal: true

module Integrations
  # class to compare passed records
  class CompareRecords
    attr_reader :records_to_delete, :records_to_create, :records_to_update, :identifier

    def initialize(entity_klass, identifier)
      @entity_klass = entity_klass
      @identifier = identifier
    end

    def add_old_entry(records_set)
      @old_entry = records_set
    end

    def add_new_entry(records_set)
      @new_entry = records_set
    end

    # rubocop:disable Metrics/AbcSize
    def changed_records
      new_keys = @new_entry.collect { |record| record[identifier] }
      old_keys = @old_entry.collect { |record| record[identifier] }
      new_keys_found = new_keys - old_keys
      old_keys_not_found = old_keys - new_keys
      matched_keys = old_keys & new_keys

      @records_to_delete = @old_entry.select { |record| old_keys_not_found.include?(record[identifier]) }
      @records_to_create = @new_entry.select { |record| new_keys_found.include?(record[identifier]) }
      @records_to_update =
        matched_keys.collect do |matched_key|
          old_record = @old_entry.detect { |record| record[identifier] == matched_key }
          new_record = @new_entry.detect { |record| record[identifier] == matched_key }
          result = old_record.values.compact <=> new_record.values.compact
          result.zero? ? nil : new_record
        end.compact
    end
    # rubocop:enable Metrics/AbcSize
  end
end
