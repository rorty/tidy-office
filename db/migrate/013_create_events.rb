Sequel.migration do
  up do
    create_table :events do
      primary_key :id
      foreign_key :place_id,       :places
      foreign_key :cartridge_id,   :cartridges
      foreign_key :device_id,     :devices
      foreign_key :contract_id,    :contracts
      Integer     :type_id,        :null => false
      Integer     :action 
      DateTime    :created_at,     :null => false
    end
  end

  down do
    drop_table :events
  end
end
