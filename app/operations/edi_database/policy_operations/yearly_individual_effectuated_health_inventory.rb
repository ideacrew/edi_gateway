# frozen_string_literal: true

module EdiDatabase
  module PolicyOperations
    # Return an inventory, from GlueDB, for all non-canceled, effectuated IVL
    # health policies active during a calendar year.
    class YearlyIndividualEffectuatedHealthInventory
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_params = yield validate_params(params)
        query_enrollment_group_ids(validated_params)
      end

      def validate_params(params)
        result = ::EdiDatabase::PolicyYearQueryContract.new.call(params)
        result.success? ? Success(result.values) : Failure(result.errors.to_h)
      end

      # rubocop:disable Metrics/MethodLength
      def query_enrollment_group_ids(params)
        start_date = Date.new(params[:year], 1, 1)
        query = ::Policy.collection.aggregate([
                                                {"$match" => {
                                                  "enrollees" => {
                                                    "$elemMatch" => {
                                                      "coverage_start" => {"$gte" => start_date},
                                                      "cp_id" => {"$ne" => nil}
                                                    }
                                                  }
                                                }},
                                                { "$unwind" => "$enrollees"},
                                                { "$match" => {
                                                  "enrollees.rel_code" => "self"
                                                }},
                                                { "$lookup" => {
                                                  "from" => "plans",
                                                  "localField" => "plan_id",
                                                  "foreignField" => "_id",
                                                  "as" => "plan"
                                                }},
                                                { "$unwind" => "$plan" },
                                                { "$match" => {
                                                  "plan.coverage_type" => "health",
                                                  "plan.year" => params[:year],
                                                  "plan.metal_level" => {"$ne" => "catastrophic"}
                                                }},
                                                { "$group" => {
                                                  "_id" => "$eg_id",
                                                  "coverage_start" => {"$first" => "$enrollees.coverage_start"},
                                                  "coverage_end" => {"$first" => "$enrollees.coverage_end"}
                                                }}
                                              ])
        without_cancels = query.lazy.reject do |q|
          (q["coverage_start"] == q["coverage_end"]) || (q["coverage_start"] >= Date.today.beginning_of_month)
        end
        mapped_query = without_cancels.map do |q|
          q["_id"]
        end
        Success(mapped_query)
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
