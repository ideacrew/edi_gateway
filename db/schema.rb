# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_02_26_192900) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "keepr_accounts", id: :serial, force: :cascade do |t|
    t.integer "number", null: false
    t.string "ancestry"
    t.string "name", null: false
    t.integer "kind", null: false
    t.integer "keepr_group_id"
    t.string "accountable_type"
    t.integer "accountable_id"
    t.integer "keepr_tax_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["accountable_type", "accountable_id"], name: "index_keepr_accounts_on_accountable"
    t.index ["ancestry"], name: "index_keepr_accounts_on_ancestry"
    t.index ["keepr_group_id"], name: "index_keepr_accounts_on_keepr_group_id"
    t.index ["keepr_tax_id"], name: "index_keepr_accounts_on_keepr_tax_id"
    t.index ["number"], name: "index_keepr_accounts_on_number"
  end

  create_table "keepr_cost_centers", id: :serial, force: :cascade do |t|
    t.string "number", null: false
    t.string "name", null: false
    t.text "note"
  end

  create_table "keepr_groups", id: :serial, force: :cascade do |t|
    t.integer "target", null: false
    t.string "number"
    t.string "name", null: false
    t.boolean "is_result", default: false, null: false
    t.string "ancestry"
    t.index ["ancestry"], name: "index_keepr_groups_on_ancestry"
  end

  create_table "keepr_journals", id: :serial, force: :cascade do |t|
    t.string "number"
    t.date "date", null: false
    t.string "subject"
    t.string "accountable_type"
    t.integer "accountable_id"
    t.text "note"
    t.boolean "permanent", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["accountable_type", "accountable_id"], name: "index_keepr_journals_on_accountable"
    t.index ["date"], name: "index_keepr_journals_on_date"
  end

  create_table "keepr_postings", id: :serial, force: :cascade do |t|
    t.integer "keepr_account_id", null: false
    t.integer "keepr_journal_id", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.integer "keepr_cost_center_id"
    t.string "accountable_type"
    t.integer "accountable_id"
    t.index ["accountable_type", "accountable_id"], name: "index_keepr_postings_on_accountable"
    t.index ["keepr_account_id"], name: "index_keepr_postings_on_keepr_account_id"
    t.index ["keepr_cost_center_id"], name: "index_keepr_postings_on_keepr_cost_center_id"
    t.index ["keepr_journal_id"], name: "index_keepr_postings_on_keepr_journal_id"
  end

  create_table "keepr_taxes", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.decimal "value", precision: 8, scale: 2, null: false
    t.integer "keepr_account_id", null: false
    t.index ["keepr_account_id"], name: "index_keepr_taxes_on_keepr_account_id"
  end

  create_table "user_fees_customers", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "hbx_id", null: false
    t.string "customer_role", null: false
    t.boolean "is_active", null: false
    t.string "insurance_coverage_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_user_fees_customers_on_account_id"
    t.index ["customer_role"], name: "index_user_fees_customers_on_customer_role"
    t.index ["hbx_id"], name: "unique_hbx_ids", unique: true
    t.index ["is_active"], name: "index_user_fees_customers_on_is_active"
  end

  add_foreign_key "user_fees_customers", "keepr_accounts", column: "account_id"
end
