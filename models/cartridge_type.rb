class CartridgeType < Sequel::Model
  one_to_many :cartridge_model
  dataset_module do 
    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end
  end
  def validate
    validates_presence :name
  end
end