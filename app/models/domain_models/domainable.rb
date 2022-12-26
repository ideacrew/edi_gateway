# frozen_string_literal: true

# This module handles behavior for maintaining a document's history
module DomainModels
  # This module handles behavior for maintaining a document's history
  module Domainable
    extend ActiveSupport::Concern

    included do
      # field :sequential_id, type: Integer
      # field :start_at, type: Time
      # field :end_at, type: Time

      # set_callback :create, :before, :set_sequential_id
      # set_callback :create, :before, :set_start_at
      # set_callback :update, :before, :set_end_at

      def id
        _id.to_s
      end

      def to_hash
        self.serializable_hash(except: :_id).deep_symbolize_keys.merge(id: _id.to_s)
      end

      # def validate_values
      #   binding.pry
      #   validation_contract_klass.new.call(self.to_hash)
      # end

      private

      # def validation_contract_klass
      #   binding.pry
      #   self.class.name
      # end

      def to_deep_hash; end

      # alias_method to_h to_hash
    end

    def set_sequential_id
      next_id = 0 # find max id of instances of this class and increment by one. or set to 0
      self.sequential_id = next_id
    end

    # Update the start_at field on the Document to the current time. This is
    # only called on create.
    #
    # @example Set the start_at time.
    #   person_name.set_start_at
    def set_start_at
      self.created_at = TimeKeeper.datetime_of_record unless start_at

      self.class.clear_timeless_option
    end

    # Update the end_at field on the Document to the current time.
    # This is only called on save.
    #
    # @example Set the end_at time.
    #   person_name.set_end_at
    def set_end_at
      self.end_at = TimeKeeper.datetime_of_record
    end
  end
end
