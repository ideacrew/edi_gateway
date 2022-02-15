module Policies
  module ValueObjects
    class Provider < Sequent::ValueObject
      attrs({
        hbx_provider_id: String,
        name: String,
        fein: String
      })
    end

    class Product < Sequent::ValueObject
      attrs({
        hios_id: String,
        coverage_year: String,
        coverage_kind: String,
        product_name: String,
        provider_name: String
      })
    end

    class Sponsor < Sequent::ValueObject
      attrs({
        hbx_sponsor_id: String,
        name: String,
        fein: String
      })
    end

    class Enrollee < Sequent::ValueObject
      attrs({
        hbx_member_id: String,
        premium: BigDecimal,
        rate_schedule_date: DateTime,
        relationship: String
      })
    end

    class CoverageSpan < Sequent::ValueObject
      attrs({
        enrollment_id: String,
        coverage_start: DateTime,
        coverage_end: DateTime,
        enrollees: array(Enrollee),
        total_cost: BigDecimal,
        applied_aptc: BigDecimal,
        employer_assistance_amount: BigDecimal,
        responsible_amount: BigDecimal
      })

      validates_presence_of :enrollment_id, :coverage_start
      validates_presence_of :total_cost, :responsible_amount
      validate :one_type_of_assistance_present

      def one_type_of_assistance_present
        if employer_assistance_amount.blank? && applied_aptc.blank?
          errors.add(:base, "either employer assistance or applied aptc must be present")
        end
      end
    end
  end
end