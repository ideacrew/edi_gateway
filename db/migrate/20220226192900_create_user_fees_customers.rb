# frozen_string_literal: true

# Generate {UserFees::Customer} active record table
class CreateUserFeesCustomers < ActiveRecord::Migration[6.1]
  def change
    create_table :user_fees_customers do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :hbx_id, null: false, index: { unique: true, name: 'unique_hbx_ids' }
      t.string :customer_role, null: false
      t.boolean :is_active, null: false
      t.string :insurance_coverage_id
      t.timestamps
    end

    add_index :user_fees_customers, :customer_role
    add_index :user_fees_customers, :is_active
    add_reference :user_fees_customers, :account, null: false, foreign_key: { to_table: :keepr_accounts }
    # add_reference :user_fees_customers, :insurance_coverage, null: false, foreign_key: true, index: false
  end
end
