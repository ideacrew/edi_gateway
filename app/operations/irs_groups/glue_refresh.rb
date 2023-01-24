# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with policy information
  class GlueRefresh
    include Dry::Monads[:result, :do, :try]
    PROCESSING_BATCH_SIZE = 5000

    def call(params)
      values = yield validate(params)
      policies = yield fetch_glue_policies_for_year(values)
      exclusion_policies = yield construct_exclusion_policies(values)
      result = yield process(policies, exclusion_policies)
      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "start_date #{params[:start_date]} is not a valid Date" unless params[:start_date].is_a?(Date)
      errors << "end_date #{params[:end_date]} is not a valid Date" unless params[:end_date].is_a?(Date)
      errors << "exclusion_list required" unless params[:exclusion_list] # array of primary hbx  ids

      errors.empty? ? Success(params) : Failure(errors)
    end

    def fetch_glue_policies_for_year(params)
      Success(Policy.where(:enrollees => { '$elemMatch' => { :coverage_start => { :'$gte' => params[:start_date],
                                                                                  :'$lt' => params[:end_date] } } }))
    end

    def construct_exclusion_policies(values)
      exclusion_policies = values[:exclusion_list].inject({}) do |exclusion_policies, primary_hbx_id|
        policies = policies_by_primary(primary_hbx_id)
        policies.each do |policy|
          exclusion_policies[policy.eg_id] = primary_hbx_id
        end
        exclusion_policies
      end

      Success(exclusion_policies)
    end

    def processing_batch_size
      @batch_size || PROCESSING_BATCH_SIZE
    end

    def process(polices, policies_to_exclude)
      query_offset = 0

      while policies.count > query_offset
        batched_policies = policies.skip(query_offset).limit(processing_batch_size)
        GlueBatchRefreshDirector.new.call(policies: batched_policies.pluck(:eg_id), policies_to_exclude: exclusion_policies)
        query_offset += processing_batch_size
        p "Processed #{query_offset} policies."
      end

      Success(response)
    end
  end
end

  