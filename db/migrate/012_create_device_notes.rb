Sequel.migration do
  up do
    create_table :device_notes do
      primary_key :id
      foreign_key :device_id,    :devices
      Text        :note,          :null => false
      DateTime    :created_at,    :null => false
      DateTime    :updated_at,    :null => false
    end
  end

  down do
    drop_table :device_notes
  end
end
