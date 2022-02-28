class MonthlyDateUtilities
  def self.start_of_month_for(date)
    date_result = date
    while(date_result.prev_day.month == date_result.month)
      date_result = date_result.prev_day
    end
    date_result
  end

  def self.is_start_of_month?
    date.month != date.prev_day.month
  end

  def self.is_end_of_month?(date)
    date.month != date.next_day.month
  end

  def self.end_of_month_for(date)
    date_result = date
    while(date_result.next_day.month == date_result.month)
      date_result = date_result.next_day
    end
    date_result
  end
end