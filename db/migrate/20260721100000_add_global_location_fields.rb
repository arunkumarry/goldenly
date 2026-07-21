class AddGlobalLocationFields < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :country, :string
    add_column :users, :location, :string
    add_column :members, :country, :string
    add_column :members, :location, :string
  end
end
