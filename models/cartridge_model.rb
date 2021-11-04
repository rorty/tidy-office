class CartridgeModel < Sequel::Model
  many_to_one :cartridge_type, graph_select: [:id, :name]
	many_to_one :manufacturer, graph_select: [:id, :name]
	one_to_many :cartridge
  dataset_module do
    order :by_name, :manufacturer_id, :name
    def options
      select(:id, :name)
        .where(disabled: false)
        .eager_graph(:manufacturer, :cartridge_type)
        .order(Sequel[:manufacturer][:name]).all
        .map do |row|
          { value: row.id, text: "#{row.manufacturer.name} #{row.name}", group: row.cartridge_type.name }
        end
    end
    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([CARTRIDGE_MODELS].[NAME]) LIKE upper(:s) OR upper([MANUFACTURER].[NAME]) LIKE upper(:s) OR upper([CARTRIDGE_TYPE].[NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end

    def prepare
      select(:id, :name, :disabled).eager_graph(:manufacturer, :cartridge_type).order(Sequel[:cartridge_type][:name], Sequel[:manufacturer][:name], :name)
    end
  end

  def validate
    validates_presence :cartridge_type_id
    validates_presence :manufacturer_id
    validates_presence :name
  end

  def title
    "#{cartridge_type.name} #{manufacturer.name} #{name}"
  end

  def totals
    #Cartridge.totals id
  end
end