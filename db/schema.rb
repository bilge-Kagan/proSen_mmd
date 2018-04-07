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

ActiveRecord::Schema.define(version: 20180120111208) do

  create_table "bounds", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "sensor_id"
    t.float "temperature_bound", limit: 24, default: 23.0, null: false
    t.float "humidity_bound", limit: 24, default: 45.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["sensor_id"], name: "index_bounds_on_sensor_id"
  end

  create_table "measurements", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "sensor_id", null: false
    t.float "temperature", limit: 24, null: false
    t.float "humidity", limit: 24, null: false
    t.datetime "record_time", null: false
    t.index ["record_time"], name: "index_measurements_on_record_time"
    t.index ["sensor_id"], name: "index_measurements_on_sensor_id"
  end

  create_table "overflows", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "sensor_id"
    t.float "temperature", limit: 24
    t.float "humidity", limit: 24
    t.datetime "record_time"
    t.index ["sensor_id"], name: "index_overflows_on_sensor_id"
  end

  create_table "sensors", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.float "last_temperature", limit: 24
    t.float "last_humidity", limit: 24
    t.datetime "last_record_time"
    t.index ["name"], name: "index_sensors_on_name", unique: true
  end

  create_table "statistics", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "sensor_id", null: false
    t.integer "measurement_number", default: 0, null: false
    t.float "max_temperature", limit: 24
    t.float "max_humidity", limit: 24
    t.float "min_temperature", limit: 24
    t.float "min_humidity", limit: 24
    t.float "mean_temperature", limit: 24
    t.float "mean_humidity", limit: 24
    t.index ["sensor_id"], name: "index_statistics_on_sensor_id"
  end

  add_foreign_key "bounds", "sensors"
  add_foreign_key "measurements", "sensors"
  add_foreign_key "overflows", "sensors"
  add_foreign_key "statistics", "sensors"
end
