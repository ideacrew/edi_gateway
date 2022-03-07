# frozen_string_literal: true

module UserFees
  # A person on the ACA Individual Market who is responsible for paying a family group's insurance premiums
  class Customer < ::ApplicationRecord
    belongs_to :account, class_name: '::Keepr::Account'

    validates_associated :account
    validates :insurance_coverage_id, presence: true
    validate :insurance_coverage_is_valid

    after_save :persist_insurance_coverage

    def insurance_coverage
      return @insurance_coverage if defined?(@insurance_coverage)
      @insurance_coverage = ::UserFees::InsuranceCoverage.find(insurance_coverage_id) unless insurance_coverage_id.nil?
    end

    # Supports a 'has_one' association between an ActiveRecord UserFees::Customer and a Mongoid ActiveModel
    #   {UserFees::InsuranceCoverage} instance
    # @param [Hash] opts the options for referencing the InsuranceCoverage instance
    # @param opts [Hash] :obj a hash that will validate using: {::AcaEntities::Ledger::Contracts::InsuranceCoverageContract}
    # @param opts [::UserFees::InsuranceCoverage] :obj an instance of {UserFees::InsuranceCoverage}
    def insurance_coverage=(obj)
      coverage = obj if obj.is_a?(::UserFees::InsuranceCoverage)
      coverage = ::UserFees::InsuranceCoverage.new(obj) if obj.is_a?(Hash)
      raise ArgumentError, 'expected ::UserFees::InsuranceCoverage or Hash' unless coverage.present?
      self.insurance_coverage_id = coverage.id.to_s
      @insurance_coverage = coverage
    end

    def to_hash
      self.serializable_hash.symbolize_keys.merge(
        account: self.account.serializable_hash.symbolize_keys,
        insurance_coverage: self.insurance_coverage.to_hash
      )
    end

    alias to_h to_hash

    private

    def insurance_coverage_is_valid
      return if insurance_coverage.nil?
      errors.add(:insurance_coverage_id, insurance_coverage.errors) if insurance_coverage.invalid?
    end

    def persist_insurance_coverage
      insurance_coverage.save if insurance_coverage.changed? || insurance_coverage.children_changed?
    end
  end
end
