Sequel.migration do
  up do
    create_table :device_models do
      primary_key :id
      foreign_key :manufacturer_id, :manufacturers
      foreign_key :device_type_id, :device_types
      String      :name, size: 128,            :null => false
      Bit         :disabled,  :null => false, :default => 0
      Text        :description
    end
  end

  down do
    drop_table :device_models
  end
end
