# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110223110532) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",        :default => 0
    t.datetime "created_at"
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "currencies", :force => true do |t|
    t.string  "name",               :limit => 160
    t.string  "code",               :limit => 3
    t.string  "integer_template",   :limit => 32
    t.string  "delimiter",          :limit => 8
    t.string  "fraction_template",  :limit => 16
    t.integer "decimal_precision",                 :default => 2,              :null => false
    t.string  "rounding_algorithm", :limit => 32,  :default => "mathematical", :null => false
    t.string  "symbol",             :limit => 16
    t.boolean "show_after_number",                 :default => false,          :null => false
  end

  create_table "donations", :force => true do |t|
    t.integer  "user_id"
    t.string   "user_name",            :limit => 150,                    :null => false
    t.string   "user_email",           :limit => 200,                    :null => false
    t.integer  "poll_id"
    t.string   "poll_title",           :limit => 60,                     :null => false
    t.integer  "currency_id"
    t.string   "workflow_state",       :limit => 16,                     :null => false
    t.boolean  "redistribution",                      :default => false
    t.boolean  "debit",                               :default => false
    t.integer  "source_poll_id"
    t.string   "source_poll_title",    :limit => 60
    t.integer  "invoice_number"
    t.text     "notes"
    t.text     "authorisation_tokens"
    t.string   "amount_integer",                                         :null => false
    t.string   "amount_fraction",                                        :null => false
    t.float    "amount_for_sorting"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "donations", ["currency_id"], :name => "index_donations_on_currency_id"
  add_index "donations", ["poll_id"], :name => "index_donations_on_poll_id"
  add_index "donations", ["user_id"], :name => "index_donations_on_user_id"

  create_table "invoice_numbers", :force => true do |t|
    t.integer "last_number_used", :default => 0, :null => false
  end

  create_table "polls", :force => true do |t|
    t.string   "title_en",          :limit => 60
    t.text     "description_en"
    t.integer  "votes"
    t.integer  "user_id"
    t.integer  "currency_id"
    t.string   "workflow_state",    :limit => 16, :null => false
    t.string   "total_integer",                   :null => false
    t.string   "total_fraction",                  :null => false
    t.float    "total_for_sorting"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "polls", ["currency_id"], :name => "index_polls_on_currency_id"
  add_index "polls", ["user_id"], :name => "index_polls_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "name",        :limit => 150,                    :null => false
    t.string   "email",       :limit => 200,                    :null => false
    t.boolean  "admin",                      :default => false
    t.text     "preferences"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
