class CreateSensors < ActiveRecord::Migration[5.1]
  def change
    create_table :sensors do |t|
      t.string :name, null: false
      t.float :last_temperature, null: true
      t.float :last_humidity, null: true
      t.datetime :last_record_time, null: true
    end
    add_index :sensors, :name, unique: true
  end
end
