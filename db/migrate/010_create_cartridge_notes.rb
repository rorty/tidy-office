Sequel.migration do
  up do
    create_table :cartridge_notes do
      primary_key :id
      foreign_key :cartridge_id, :cartridges
      Text        :note,              :null => false
      DateTime    :created_at,        :null => false
      DateTime    :updated_at,        :null => false
    end
  end

  down do
    drop_table :cartridge_notes
  end
end
