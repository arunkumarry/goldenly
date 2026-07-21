class CreateServiceCatalogsAndLinkServiceRequests < ActiveRecord::Migration[8.1]
  CATALOGUE = [
    [ 0, "Medical Health Checkup", "Book a medical health checkup." ],
    [ 1, "Household Help", "Help with household tasks and errands." ],
    [ 2, "Shopping", "Groceries and other essential shopping." ],
    [ 3, "Transport", "Transport to appointments and other destinations." ],
    [ 4, "Companion Visit", "A friendly companion visit." ],
    [ 5, "Digital Assistance", "Help with phones, devices, and digital services." ]
  ].freeze

  def up
    create_table :service_catalogs do |t|
      t.integer :kind, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :service_catalogs, :kind, unique: true

    CATALOGUE.each do |kind, name, description|
      execute <<~SQL.squish
        INSERT INTO service_catalogs (kind, name, description, active, created_at, updated_at)
        VALUES (#{kind}, #{connection.quote(name)}, #{connection.quote(description)}, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end

    add_reference :service_requests, :service_catalog, foreign_key: true

    execute <<~SQL.squish
      UPDATE service_requests
      SET service_catalog_id = (
        SELECT id FROM service_catalogs
        WHERE kind = CASE
          WHEN LOWER(service_type) ~ '(household|clean|cook|errand)' THEN 1
          WHEN LOWER(service_type) ~ '(shop|grocery|essential)' THEN 2
          WHEN LOWER(service_type) ~ '(transport|ride)' THEN 3
          WHEN LOWER(service_type) ~ '(companion|visit)' THEN 4
          WHEN LOWER(service_type) ~ '(digital|phone|device)' THEN 5
          ELSE 0
        END
      )
    SQL
    change_column_null :service_requests, :service_catalog_id, false
  end

  def down
    remove_reference :service_requests, :service_catalog, foreign_key: true
    drop_table :service_catalogs
  end
end
