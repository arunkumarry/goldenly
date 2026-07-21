class AddDiagnosticServiceCatalog < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO service_catalogs (kind, name, description, active, created_at, updated_at)
      VALUES (6, 'Diagnostic Service', 'Book diagnostic tests such as blood tests, X-rays, urine tests, and kidney tests.', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT (kind) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, active = TRUE, updated_at = CURRENT_TIMESTAMP
    SQL
  end

  def down
    execute "DELETE FROM service_catalogs WHERE kind = 6"
  end
end
