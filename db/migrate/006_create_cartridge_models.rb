Sequel.migration do
  up do
    create_table :cartridge_models do
      primary_key :id
      foreign_key :manufacturer_id,    :manufacturers
      foreign_key :cartridge_type_id,  :cartridge_types
      String      :name, size: 128,    :null => false
      Bit         :disabled,  :null => false, :default => 0
      Text        :description
    end
  end

  down do
    drop_table :cartridge_models
  end
end
