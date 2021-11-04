Sequel.migration do
  up do
    create_table :contracts do
      primary_key :id
      String      :name, size: 128,    :null => false
      String      :type, size: 128
      Bit         :enabled, :null => false, :default => 1
      DateTime    :concluded_at 
      Text        :description
    end
  end
  down do
    drop_table :contracts
  end
end
