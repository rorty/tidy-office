Sequel.migration do
  up do
    create_table :device_types do
      primary_key :id
      String :name, size: 128, :null => false
      Bit    :compatibility,   :null => false, :default => 0
    end
  end
  down do
    drop_table :device_types
  end
end