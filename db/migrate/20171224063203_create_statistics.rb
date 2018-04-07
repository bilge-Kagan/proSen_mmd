class CreateStatistics < ActiveRecord::Migration[5.1]
  def change
    create_table :statistics do |t|
      t.references :sensor, foreign_key: true, null: false
      t.integer :measurement_number, null: false, default: 0
      t.float :max_temperature, null: true
      t.float :max_humidity, null: true
      t.float :min_temperature, null: true
      t.float :min_humidity, null: true
      t.float :mean_temperature, null: true
      t.float :mean_humidity, null: true
    end
  end
end
