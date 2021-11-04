Sequel.migration do
  up do
    create_table :compatibilities do
      primary_key :id
      foreign_key :device_model_id,     :device_models
      foreign_key :cartridge_model_id,   :cartridge_models
    end
  end
  down do
    drop_table :compatibilities
  end
end
