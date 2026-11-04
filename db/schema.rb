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

ActiveRecord::Schema[7.2].define(version: 2026_11_04_000600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "applies", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "geek_id", null: false
    t.boolean "read", default: false, null: false
    t.boolean "invited", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["geek_id"], name: "index_applies_on_geek_id"
    t.index ["job_id"], name: "index_applies_on_job_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "location", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false, null: false
  end

  create_table "geeks", force: :cascade do |t|
    t.string "name", null: false
    t.string "stack", null: false
    t.text "resume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string "name", null: false
    t.string "place", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false, null: false
    t.index ["company_id"], name: "index_jobs_on_company_id"
  end

  add_foreign_key "applies", "geeks"
  add_foreign_key "applies", "jobs"
  add_foreign_key "jobs", "companies"
end
