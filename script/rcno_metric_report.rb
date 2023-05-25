# frozen_string_literal: true

["rcno_carrier_hios_id_48396.csv", "rcno_carrier_hios_id_96667.csv", "rcno_carrier_hios_id_33653.csv",
 "rcno_carrier_hios_id_50165.csv", "rcno_carrier_hios_id_54879.csv"].each do |file|
  @hash = Hash.new

  [:first_name, :last_name, :dob, :subscriber_indicator, :issuer_subscriber_id, :exchange_policy_id, :issuer_member_id,
   :issuer_policy_id, :qhp_id, :benefit_start_date, :benefit_end_date, :aptc_amount, :aptc_start_date, :aptc_end_date,
   :premium_amount, :premium_start_date, :premium_end_date, :member_premium_amount, :member_premium_start_date,
   :member_premium_end_date, :effectuation_status, :overall_indicator].each do |indicator|
    ["m", "i", "d", "u", "g", "n", "k", "f", "r"].each do |letter|
      status = "#{indicator}_#{letter}".to_sym
      @hash.merge!(:"#{status}".to_sym => 0)
    end
  end

  file_name = "#{Rails.root}/#{file}"
  next unless File.exist?(file_name)

  File.readlines(file_name, chomp: true).each do |line|
    row = line.split("|")

    def letter_code_counter(key, match)
      case match
      when "M"
        @hash["#{key}_m".to_sym] += 1
      when "U"
        @hash["#{key}_u".to_sym] += 1
      when "D"
        @hash["#{key}_d".to_sym] += 1
      when "I"
        @hash["#{key}_i".to_sym] += 1
      when "G"
        @hash["#{key}_g".to_sym] += 1
      when "N"
        @hash["#{key}_n".to_sym] += 1
      when "K"
        @hash["#{key}_k".to_sym] += 1
      when "F"
        @hash["#{key}_f".to_sym] += 1
      when "R"
        @hash["#{key}_r".to_sym] += 1
      end
    end

    letter_code_counter(:first_name, row[9])
    letter_code_counter(:last_name, row[15])
    letter_code_counter(:dob, row[18])
    letter_code_counter(:subscriber_indicator, row[27])
    letter_code_counter(:issuer_subscriber_id, row[39])
    letter_code_counter(:exchange_policy_id, row[45])
    letter_code_counter(:issuer_member_id, row[42])
    letter_code_counter(:issuer_policy_id, row[48])
    letter_code_counter(:qhp_id, row[93])
    letter_code_counter(:benefit_start_date, row[96])
    letter_code_counter(:benefit_end_date, row[99])
    letter_code_counter(:aptc_amount, row[102])
    letter_code_counter(:aptc_start_date, row[105])
    letter_code_counter(:aptc_end_date, row[108])
    letter_code_counter(:premium_amount, row[120])
    letter_code_counter(:premium_start_date, row[123])
    letter_code_counter(:premium_end_date, row[126])
    letter_code_counter(:member_premium_amount, row[129])
    letter_code_counter(:member_premium_start_date, row[132])
    letter_code_counter(:member_premium_end_date, row[135])
    letter_code_counter(:effectuation_status, row[138])
    letter_code_counter(:overall_indicator, row[139])
  end

  result = file.split("_")
  CSV.open("#{Rails.root}/rcno_overall_status_#{result.last}", "w", col_sep: ",") do |csv|
    csv << ["Field", "M", "I", "D", "U", "G", "N", "K", "F", "R"]

    [:first_name, :last_name, :dob, :subscriber_indicator, :issuer_subscriber_id, :exchange_policy_id, :issuer_member_id,
     :issuer_policy_id, :qhp_id, :benefit_start_date, :benefit_end_date, :aptc_amount, :aptc_start_date, :aptc_end_date,
     :premium_amount, :premium_start_date, :premium_end_date, :member_premium_amount, :member_premium_start_date,
     :effectuation_status, :overall_indicator].each do |key|
      csv << [key.to_s, @hash["#{key}_m".to_sym], @hash["#{key}_i".to_sym], @hash["#{key}_d".to_sym], @hash["#{key}_u".to_sym],
              @hash["#{key}_g".to_sym], @hash["#{key}_n".to_sym], @hash["#{key}_k".to_sym], @hash["#{key}_f".to_sym],
              @hash["#{key}_r".to_sym]]
    end
  end
end
