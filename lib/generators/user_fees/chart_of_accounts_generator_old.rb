# frozen_string_literal: true

module UserFees
  class ChartOfAccountsGenerator < Rails::Generators::Base
    desc 'This generator initializes a State-based Exchange User Fee Chart of Accounts configuration file at system/config'
    def create_yaml_file
      create_file 'system/config/user_fees/chart_of_accounts.yml', '# Add yml content here'
    end
  end
end
