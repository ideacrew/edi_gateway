namespace :data do
  desc "Load initial dumps from Enroll"
  task :load_initial_enrollment_status => :environment do
    data_str = File.read("enrollment_data.json")
    data = JSON.parse(data_str)
    filtered_data = data.select do |rec|
      build_result = PolicyInventory::BuildCoverageSpanFromInventory.new.call(rec)
      unless build_result.success?
        puts build_result.failure.inspect
      end
      build_result.success?
    end
    sorted_data = filtered_data.sort_by do |rec|
      build_result = PolicyInventory::BuildCoverageSpanFromInventory.new.call(rec)
      build_result.value!.coverage_start
    end
    sorted_data.each do |rec|
      result = PolicyInventory::ImportSpanRecord.new.call(rec)
      if !result.success?
        puts result.inspect
      end
    end
  end
end
