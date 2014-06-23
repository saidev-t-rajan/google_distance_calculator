class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name
      t.string :mrn
      t.string :street_address
      t.string :suburb
      t.string :postcode
      t.string :destination
      t.integer :distance_meters
      t.string :distance_text
      t.integer :duration_seconds
      t.string :duration_text

      t.timestamps
    end
  end
end
