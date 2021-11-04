Sequel.migration do
  up do
    create_table :cartridges do
      primary_key :id
      foreign_key :cartridge_model_id,  :cartridge_models
      foreign_key :device_id,          :devices,   :null => true
      String      :code,     size: 4,   :null => false,  :unique => true
      String      :status,   size: 12 , :null => false, :default => "reserved"
      Integer     :refill_count,        :null => false, :default => 0
      Text        :description
      DateTime    :changed_at,    :null => false
      DateTime    :created_at,    :null => false
      DateTime    :updated_at,    :null => false
    end
    add_index :cartridges, [:code], :unique => true
  end
  
  
  down do
    drop_table :cartridges
  end
end
