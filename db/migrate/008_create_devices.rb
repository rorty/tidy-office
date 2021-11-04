Sequel.migration do
  up do
    create_table :devices do
      primary_key :id
      foreign_key :device_model_id, :device_models
      foreign_key :place_id, :places
      String      :code,  size: 5, :null => false
      String      :inventory_number, size: 32
      String      :status,     size: 12 , :null => false, :default => "reserved"
      Text        :description
      DateTime    :changed_at,    :null => false
      DateTime    :created_at,    :null => false
      DateTime    :updated_at,    :null => false
    end
    add_index :devices, [:code], :unique => true
  end

  down do
    drop_table :devices
  end
end
