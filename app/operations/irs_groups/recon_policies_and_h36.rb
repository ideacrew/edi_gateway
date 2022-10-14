# frozen_string_literal: true

require "csv"

module IrsGroups
  # Recon a set of H36 files with policy information.
  #
  # Needs :path and :year parameters.
  class ReconPoliciesAndH36
    include Dry::Monads[:result, :do, :try]

    def call(params)
      validated_params = yield validate_params(params)
      edidb_policy_ids = yield query_policies(validated_params)
      h36_files = yield get_files_list(validated_params)
      perform_recon(edidb_policy_ids, h36_files)
    end

    def validate_params(params)
      result = ::IrsGroups::H36ReconRequestContract.new.call(params)
      return Failure(result.errors.to_h) unless result.success?
      return Failure("invalid path: #{result.values[:path]}") unless File.exist?(result.values[:path])
      return Failure("not a directory: #{result.values[:path]}") unless File.directory?(result.values[:path])

      Success(result.values)
    end

    def get_files_list(params)
      path = File.expand_path(params[:path])
      search_expression = File.join(path, "*.xml")
      file_list = Dir.glob(search_expression).to_a
      return Failure("no h36 files found in: #{path}") unless file_list.any?

      Success(file_list)
    end

    def query_policies(params)
      ::EdiDatabase::PolicyOperations::YearlyIndividualEffectuatedHealthInventory.new.call({
                                                                                             year: params[:year]
                                                                                           })
    end

    def perform_recon(policy_id_list, files_list)
      policy_list = policy_id_list.to_a
      found_policy_ids = Array.new
      CSV.open("irs_group_policy_mappings.csv", "wb") do |csv|
        csv << ["Enrollment Group ID", "IRS Group ID"]
        files_list.each do |f|
          result = IrsGroups::ReadIrsGroupPolicyInventoryFromH36.new.call({path: f})
          next unless result.success?

          values = result.value!
          values[:policy_list].each do |pid|
            found_policy_ids.push(pid)
          end
          values[:group_mappings].each_pair do |k, v|
            v.each do |pid|
              csv << [pid, k]
            end
          end
        end
      end
      Success(record_differences(policy_list, found_policy_ids))
    end

    def record_differences(policy_list, found_policy_ids)
      difference = policy_list - found_policy_ids
      CSV.open("policies_not_in_h36.csv", "wb") do |csv|
        csv << ["Enrollment Group ID"]
        difference.each do |pid|
          csv << [pid]
        end
      end
      {
        difference: difference,
        total: policy_list.count
      }
    end
  end
end
