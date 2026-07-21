class AddStructuredPlaceFields < ActiveRecord::Migration[8.0]
  def change
    [ :users, :care_profiles ].each do |table|
      add_column table, :address, :string
      add_column table, :city, :string
      add_column table, :region, :string
      add_column table, :country_code, :string, limit: 2
      add_column table, :postal_code, :string
      add_column table, :latitude, :decimal, precision: 10, scale: 6
      add_column table, :longitude, :decimal, precision: 10, scale: 6
      add_column table, :google_place_id, :string
      add_index table, :google_place_id
    end
  end
end
