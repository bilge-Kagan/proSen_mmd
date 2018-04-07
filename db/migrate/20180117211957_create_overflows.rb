class CreateOverflows < ActiveRecord::Migration[5.1]
  def change
    create_table :overflows do |t|
      t.references :sensor, foreign_key: true
      t.float :temperature
      t.float :humidity
      t.datetime :record_time
    end
  end
end
