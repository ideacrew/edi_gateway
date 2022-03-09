namespace :reports do
  desc "Create glue db policy report"
  task :gluedb_policy_report => :environment do
    CSV.open("gluedb_span_report.csv", "wb") do |csv|
      GluedbReports::CreateSpanReport.new.call(csv)
    end
  end
end