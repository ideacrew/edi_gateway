# frozen_string_literal: true

class UserFeesGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def copy_user_fees_feature_file
    copy_file 'user_fees_feature.yml.tt', File.join('system/config/user_fees', "#{file_name}.yml")
  end

  def create_init_coa_rake_file
    rakefile 'user_fees.rake' do
      '
        task user_fees: :init_chart_of_accounts do
          puts "COA initialized!"
        end
      '
    end
  end

  def run_init_coa_rake_task
    rake 'user_fees:init_chart_of_accounts'
  end
end
