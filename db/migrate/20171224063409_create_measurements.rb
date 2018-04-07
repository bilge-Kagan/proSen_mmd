class CreateMeasurements < ActiveRecord::Migration[5.1]
  def change
    create_table :measurements do |t|
      t.references :sensor, foreign_key: true, null: false
      t.float :temperature, null: false
      t.float :humidity, null: false
      t.datetime :record_time, null: false
    end
    add_index :measurements, :record_time
  end
end
