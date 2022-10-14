# frozen_string_literal: true

module IrsGroups
  # Read the IRS group and policy data from an H32 xml.
  class ReadIrsGroupPolicyInventoryFromH36
    include Dry::Monads[:result, :do, :try]

    XML_NS = {
      :irs_c => "urn:us:gov:treasury:irs:common",
      :irs_he => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
    }.freeze

    def call(params)
      validated_params = yield validate_params(params)
      create_inventory(validated_params)
    end

    def validate_params(params)
      result = ::IrsGroups::H36LocationContract.new.call(params)
      return Failure(result.errors.to_h) unless result.success?
      return Failure("invalid path: #{result.values[:path]}") unless File.exist?(result.values[:path])

      Success(result.values)
    end

    def create_inventory(params)
      xml_string = File.open(params[:path], "rb").read
      xml = Nokogiri::XML(xml_string)
      groups = xml.xpath("//irs_c:IRSHouseholdGrp", XML_NS)
      group_mappings = Hash.new
      policy_list = Array.new
      groups.each do |grp|
        grp_id = grp.at_xpath("irs_c:IRSGroupIdentificationNum", XML_NS).content
        group_policy_ids = Array.new
        grp.xpath(".//irs_c:InsurancePolicy/irs_c:InsuranceCoverage", XML_NS).each do |pol_node|
          pol_id = pol_node.at_xpath("irs_c:QHPPolicyNum", XML_NS).content
          group_policy_ids.push(pol_id)
        end
        uniq_policy_ids = group_policy_ids.uniq
        group_mappings[grp_id] = uniq_policy_ids
        policy_list.push(*uniq_policy_ids)
      end
      Success({
                group_mappings: group_mappings,
                policy_list: policy_list
              })
    end
  end
end
