# frozen_string_literal: true

namespace :recon do
  desc "Compare the H36 files to policy records"
  task :h36_files => :environment do
    result = ::IrsGroups::ReconPoliciesAndH36.new.call({
      year: 2022,
      path: "h36_files"
    })
    if result.success?
      values = result.value!
      puts "Found #{values[:difference].count}/#{values[:total]} policies missing from in H36."
    end
  end
end
  