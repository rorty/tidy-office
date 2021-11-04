class Manufacturer < Sequel::Model
  plugin :validation_helpers
  one_to_many :cartridge
  one_to_many :device
  
  dataset_module do 
    order :by_name, :name
    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end

  end
 
  def validate
    validates_presence :name
  end

end


