# frozen_string_literal: true

# This module helps to convert intengers to float value with 2 decimals
module MoneyMath
  def as_dollars(val)
    BigDecimal(val.to_s).round(2)
  end
end
