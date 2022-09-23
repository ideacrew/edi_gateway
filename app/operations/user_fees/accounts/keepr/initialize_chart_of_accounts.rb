# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module Accounts
    module Keepr
      # Initialize Chart of Accounts in database based on local
      # {EdiGatewayRegistry} :user_fees_feature feature switch
      class InitializeChartOfAccounts
        send(:include, Dry::Monads[:result, :do])

        def call(_params)
          _feature_enabled = yield feature_enabled?
          _hbx_accounts = yield initialize_hbx_accounts
          _insurer_accounts = yield initialize_insurer_accounts
          _journals = yield initialize_journal

          Success(true)
        end

        private

        def feature_enabled?
          if EdiGatewayRegistry[:user_fees_feature].enabled?
            Success(true)
          else
            Failure[:resource_registry_error, error: 'feature disabled']
          end
        end

        def initialize_hbx_accounts
          account_keys = EdiGatewayRegistry[:hbx_account_keys].item || []
          accounts =
            account_keys.map do |account|
              params = settings_to_hash(EdiGatewayRegistry[account].settings)
              create_account(params)
            end
          Success(accounts)
        end

        def initialize_insurer_accounts
          insurer_keys = EdiGatewayRegistry[:insurer_keys].item || []

          insurers = insurer_keys.map { |insurer_key| create_insurer_accounts(insurer_key) }
          Success(insurers)
        end

        def create_insurer_accounts(insurer_key)
          insurer = EdiGatewayRegistry[insurer_key]

          account_keys = EdiGatewayRegistry[:insurer_account_keys].item
          accounts =
            account_keys.map do |account|
              settings = settings_to_hash EdiGatewayRegistry[account].settings
              title = settings_to_hash(insurer.settings)[:title] || ''
              hios_id = settings_to_hash(insurer.settings)[:hios_id] || ''

              name = settings[:name].gsub('<insurer_title>', title)
              number = (settings[:number].to_s + hios_id.to_s).to_i
              params = settings.merge(name: name, number: number)
              create_account(params)
            end
          Success(accounts)
        end

        def create_account(params)
          return if Keepr::Account.find_by(number: params[:number]).present?
          Keepr::Account.create!(params)
        end

        def initialize_journals
          journals =
            EdiGatewayRegistry[:journal_keys].item.map do |journal|
              params =
                EdiGatewayRegistry[journal]
                  .settings
                  .reduce({}) { |attrs, setting| attrs.merge!(setting.key => setting.item) }
              create_journal(params)
            end
          Success(journals)
        end

        def initialize_chart_of_accounts; end

        def settings_to_hash(settings)
          settings.reduce({}) { |attrs, setting| attrs.merge!(setting.to_h) }
          # settings.reduce({}) { |attrs, setting| attrs.merge!(setting.key => setting.item) }
        end

        # A/R & Revenue Rollup Accounts
        def initialize_ar_and_revenue_accounts
          ar_acct = Keepr::Account.create!(number: 1100, name: 'Accounts Receivable', kind: :asset)
          revenue_acct = Keepr::Account.create!(number: 4000, name: 'Revenue', kind: :revenue)
        end

        def initialize_user_fee_accounts
          # All Carriers User Fee A/R & Revenue Accounts & Journal
          ar_user_fees_acct = Keepr::Account.create!(number: 1110, name: 'User Fees A/R', kind: :asset, parent: ar_acct)
          revenue_user_fees_acct =
            Keepr::Account.create!(number: 4110, name: 'User Fees Revenue', kind: :revenue, parent: revenue_acct)
          ar_user_fees_journal =
            Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

          # All Carriers User Fee Adjustment A/R & Revenue Accounts & Journal
          ar_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Accounts Receivable', kind: :asset)
          revenue_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Revenue', kind: :asset)
          ar_journal =
            Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')
        end

        def initalize_full_premium_accounts
          # All Carriers Full Premium A/R & Revenue Accounts & Journal
          ar_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Accounts Receivable', kind: :asset)
          revenue_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Revenue', kind: :asset)
          ar_journal =
            Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')
        end

        def initialize_carrier_accounts(values); end

        # # Individual Carrier User Fee A/R & Revenue Accounts & Journal
        # ar_user_fees_hp_acct =
        #   Keepr::Account.create!(
        #     number: 1_110_001,
        #     name: 'Harvard Pilgram User Fees A/R',
        #     kind: :asset,
        #     parent: ar_user_fees_acct
        #   )

        # revenue_user_fees_hp_acct =
        #   Keepr::Account.create!(
        #     number: 4_110_001,
        #     name: 'Harvard Pilgram User Fees Revenue',
        #     kind: :revenue,
        #     parent: revenue_user_fees_acct
        #   )
        # ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

        # # Individual Carrier User Fee Adjustment A/R & Revenue Accounts & Journal
        # ar_user_fees_adjustment_acct =
        #   Keepr::Account.create!(number: 1110, name: 'User Fees A/R', kind: :asset, parent: ar_acct)
        # revenue_user_fees_adjustment_acct =
        #   Keepr::Account.create!(number: 1110, name: 'User Fees A/R', kind: :asset, parent: ar_acct)
        # ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

        # # Individual Carrier Full Premium A/R & Revenue Accounts & Journal
        # ar_user_fees_hp_acct =
        #   Keepr::Account.create!(
        #     number: 1_110_001,
        #     name: 'Harvard Pilgram User Fees A/R',
        #     kind: :asset,
        #     parent: ar_user_fees_acct
        #   )

        # ## Account: Carrier X User Fee, Revenue, Credit
        # revenue_user_fees_hp_acct =
        #   Keepr::Account.create!(
        #     number: 4_110_001,
        #     name: 'Harvard Pilgram User Fees Revenue',
        #     kind: :revenue,
        #     parent: revenue_user_fees_acct
        #   )
        # ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

        # # Carrier Full Premium A/R Rollup Account
        # revenue_full_premium_racct =
        #   Keepr::Account.create!(number: 4000, name: 'User Fees Accounts Receivable', kind: :asset)

        # # Full Premium Journal
        # ## Account: Carrier X Full Premium Income, Revenue, Credit
        # hp_premium_income =
        #   Keepr::Account.create!(
        #     number: 4_000_001,
        #     name: 'Harvard Pilgram Full Premium Revenue',
        #     kind: :revenue,
        #     parent: ar_revenue_acct
        #   )

        # ## Account: Carrier X Full Premium Expense, Expense, Debit

        # # User Fee Adjustments Journal
        # ## Account: Carrier X User Fee Credit Adjustments, Revenue, Credit
        # ## Account: Carrier X User Fee Debit Adjustments, Expense, Debit

        # ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')
      end
    end
  end
end
