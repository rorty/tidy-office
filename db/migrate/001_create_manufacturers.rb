Sequel.migration do
  up do
    create_table :manufacturers do
      primary_key :id
      String :name, size: 128, :null => false
    end
  end

  down do
    drop_table :manufacturers
  end
end
