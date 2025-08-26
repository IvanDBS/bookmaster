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

ActiveRecord::Schema[8.0].define(version: 2025_08_15_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "status", default: "pending"
    t.bigint "user_id", null: false
    t.bigint "service_id", null: false
    t.string "client_name", null: false
    t.string "client_email", null: false
    t.string "client_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "gdpr_consent_at"
    t.datetime "data_retention_until"
    t.index ["client_email"], name: "index_bookings_on_client_email"
    t.index ["service_id"], name: "index_bookings_on_service_id"
    t.index ["start_time"], name: "index_bookings_on_start_time"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id", "start_time"], name: "index_bookings_on_user_id_and_start_time"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "duration", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "service_type", default: "маникюр", null: false
    t.index ["name"], name: "index_services_on_name"
    t.index ["price"], name: "index_services_on_price"
    t.index ["service_type"], name: "index_services_on_service_type"
    t.index ["user_id"], name: "index_services_on_user_id"
  end

  create_table "time_slots", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.integer "duration_minutes", default: 60
    t.boolean "is_available", default: true
    t.bigint "booking_id"
    t.string "slot_type", default: "work"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_time_slots_on_booking_id"
    t.index ["date", "is_available"], name: "index_time_slots_on_date_and_is_available"
    t.index ["user_id", "date", "start_time"], name: "index_time_slots_on_user_id_and_date_and_start_time", unique: true
    t.index ["user_id", "date"], name: "index_time_slots_on_user_id_and_date"
    t.index ["user_id"], name: "index_time_slots_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "role", default: "client"
    t.text "bio"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "deleted_at"
    t.datetime "gdpr_consent_at"
    t.string "gdpr_consent_version", default: "1.0"
    t.boolean "marketing_consent", default: false
    t.datetime "marketing_consent_at"
    t.datetime "data_export_requested_at"
    t.datetime "data_deletion_requested_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "working_day_exceptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.boolean "is_working", default: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_working_day_exceptions_on_date"
    t.index ["user_id", "date"], name: "index_working_day_exceptions_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_working_day_exceptions_on_user_id"
  end

  create_table "working_schedules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "day_of_week", null: false
    t.time "start_time"
    t.time "end_time"
    t.time "lunch_start"
    t.time "lunch_end"
    t.boolean "is_working", default: true
    t.integer "slot_duration_minutes", default: 60
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day_of_week"], name: "index_working_schedules_on_user_id_and_day_of_week", unique: true
    t.index ["user_id"], name: "index_working_schedules_on_user_id"
  end

  add_foreign_key "bookings", "services"
  add_foreign_key "bookings", "users"
  add_foreign_key "services", "users"
  add_foreign_key "time_slots", "bookings"
  add_foreign_key "time_slots", "users"
  add_foreign_key "working_day_exceptions", "users"
  add_foreign_key "working_schedules", "users"
end
