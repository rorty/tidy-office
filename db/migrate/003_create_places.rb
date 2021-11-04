Sequel.migration do
  up do
    create_table :places do
      primary_key :id
      String      :name,     :null => false
      Integer     :parent_id
      Text        :description
      Bit         :disabled,  :null => false, :default => 0
      Bit         :warehouse, :null => false, :default => 0
    end
  end
  down do
    drop_table :places
  end
end
