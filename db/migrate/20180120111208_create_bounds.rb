class CreateBounds < ActiveRecord::Migration[5.1]
  def change
    create_table :bounds do |t|
      t.references :sensor, foreign_key: true
      t.float :temperature_bound, null: false, default: 23.0
      t.float :humidity_bound, null: false, default: 45.0

      t.timestamps null: true
    end
  end
end
