# frozen_string_literal: true

# MoneyMath module
module MoneyMath
  # @param [BigDecimal] val
  def as_dollars(val)
    BigDecimal(val.to_s).round(2)
  end
end
