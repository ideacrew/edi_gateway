# frozen_string_literal: true

module Tax1095a
  class IrsYearlyBatchProcessDirector
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      values = yield validate(params)
      result = yield publish_families_refresh(values)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "tax_year required" unless params[:tax_year]
      errors << "tax_form_type required" unless params[:tax_form_type]
      errors << "irs_groups required and must be an array" unless params[:irs_groups].is_a?(Array)
      errors << "irs_groups_to_exclude required and must be an hash" unless params[:irs_groups_to_exclude].is_a?(Hash)

      errors.empty? ? Success(params) : Failure(errors)
    end

    # rubocop:disable Metrics/AbcSize
    def publish_families_refresh(values)
      logger = Logger.new("#{Rails.root}/log/irs_yearly_batch_process_director_#{Date.today.strftime('%Y_%m_%d')}.log")
      counter = 0
      logger.info("Operation started at #{DateTime.now} ")
      values[:irs_groups].each do |irs_group_id|
        if values[:irs_groups_to_exclude].key?(irs_group_id)
          logger.info("skipped #{irs_group_id} since its in the exclusion list")
          next
        end

        ::Tax1095a::Transformers::InsurancePolicies::Cv3Family.new.call({ tax_year: values[:tax_year],
                                                                          tax_form_type: values[:tax_form_type],
                                                                          irs_group_id: irs_group_id })
        counter += 1
        logger.info("published #{counter} out of #{values[:irs_groups].count}") if (counter % 100).zero?
      end
      logger.info("Operation ended at #{DateTime.now} ")
      Success("published all irs_groups")
    end
  end
end
