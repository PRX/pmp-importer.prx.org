# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140812191726) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "pmp_guid_mappings", force: true do |t|
    t.string   "source_name"
    t.string   "source_type"
    t.string   "source_id"
    t.string   "guid",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pmp_guid_mappings", ["guid"], name: "index_pmp_guid_mappings_on_guid", unique: true, using: :btree
  add_index "pmp_guid_mappings", ["source_name", "source_type", "source_id"], name: "by_source", unique: true, using: :btree

end
