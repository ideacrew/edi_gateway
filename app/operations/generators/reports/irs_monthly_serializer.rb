# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'
require 'fileutils'

module Generators::Reports
  # Generate a monthly IRS report
  class IrsMonthlySerializer
    send(:include, Dry::Monads[:result, :do])

    def call(params)
      calendar_year, max_month = yield validate(params)
      @h36_root_folder = yield create_h36_folder
      transmission_folder = yield create_transmission_folder
      irs_group_query = yield get_irs_group_query
      _execute = yield initialize_process(calendar_year, max_month, irs_group_query)
      _manifest = yield create_manifest(transmission_folder)
      Success("generated h36 successfully")
    end

    private

    def validate(params)
      Failure('either calendar_year is not present or calendar_year is not an integer') unless params[:calendar_year].present? || params[:calendar_year].integer?
      Failure('either max_month is not present or max_month is not an integer') unless params[:max_month].present? || params[:max_month].integer?
      @logger = Logger.new("#{Rails.root}/log/h36_exceptions.log")
      Success([params[:calendar_year], params[:max_month]])
    end

    def create_h36_folder
      path = "#{Rails.root}/irs/h36_#{Time.now.strftime('%m_%d_%Y_%H_%M')}"
      h36_root_folder = create_directory(path)
      Success(h36_root_folder)
    end

    def create_transmission_folder
      transmission_folder = create_directory("#{@h36_root_folder}/transmission")

      Success(transmission_folder)
    end

    def create_directory(path)
      if Dir.exists?(path)
        FileUtils.rm_rf(path)
      end
      FileUtils.mkdir_p(path)[0]
    end

    def get_irs_group_query
      Success InsurancePolicies::AcaIndividuals::IrsGroup.all.no_timeout
    end

    def initialize_process(calendar_year, max_month, get_irs_group_query)
      current = 0
      folder_count = 1
      create_new_irs_folder(folder_count)
      count = 0
      start = Time.now

      get_irs_group_query.each do |irs_group|
        hbx_member_id = irs_group.insurance_agreements.first.contract_holder.hbx_member_id
        primary_person = Person.where(authority_member_id: hbx_member_id).first
        if primary_person.nil?
          @logger.info("primary person not found for hbx_member_id: #{hbx_member_id}, irs_group_id: #{irs_group.irs_group_id}")
          next
        end
        policies = primary_person.policies.where(:kind.ne => "coverall").to_a
        policies.reject!{|pol| pol.plan.metal_level == "catastrophic" || pol.subscriber.coverage_start >= Date.today.beginning_of_month || !pol.subscriber.cp_id.present? || pol.plan.coverage_type == 'dental' || pol.canceled?}
        policies.reject! do |pol|
          if pol.enrollees.any?{|en| en.try(:person).try(:authority_member).blank?}
            @logger.info("For policy_id: #{pol.id} authority member missing!!, irs_group_id: #{irs_group.irs_group_id}")
          end
          next
        end
        if policies.count == 0
          @logger.info("No policies found for irs_group_id: #{irs_group.irs_group_id}")
          next
        end

        folder_path = "#{@h36_root_folder}/#{@h36_folder_name}"
        group_xml = Generators::Reports::IrsMonthlyXml.new(irs_group, policies, calendar_year, max_month, folder_path)
        group_xml.serialize

        count += 1

        if count % 50 == 0
          puts "----found #{count} families so far"
        end

        if count % 3000 == 0
          merge_and_validate_xmls(folder_count)
          folder_count += 1
          create_new_irs_folder(folder_count)
        end

        if count % 100 == 0
          puts "so far --- #{count} --- out of #{current}"
          puts "time taken for current record ---- #{Time.now - start} seconds"
          start = Time.now
        end
      rescue StandardError => e
        @logger.info("Unable to create IRS Gropu for: #{irs_group.irs_group_id} due to #{e}")
      end
      merge_and_validate_xmls(folder_count)
      Success("executed successfully")
    end

    def merge_and_validate_xmls(folder_count)
      folder_num = prepend_zeros(folder_count.to_s, 5)
      xml_merge = Generators::Reports::IrsXmlMerger.new("#{@h36_root_folder}/#{@h36_folder_name}", folder_num)
      xml_merge.irs_monthly_folder = @h36_root_folder
      xml_merge.process
      xml_merge.validate
    end

    def create_manifest(transmission_folder)
      Success(Generators::Reports::IrsMonthlyManifest.new.create("#{transmission_folder}"))
    end

    def create_new_irs_folder(folder_count)
      folder_number = prepend_zeros(folder_count.to_s, 3)
      @h36_folder_name = "IRS_H36_#{Time.now.strftime('%H_%M_%d_%m_%Y')}_#{folder_number}"
      create_directory "#{@h36_root_folder}/#{@h36_folder_name}"
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end
