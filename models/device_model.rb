class DeviceModel < Sequel::Model
  one_to_many :compatibility
  one_to_many :device
  many_to_one :device_type, graph_select: [:id, :name]
  many_to_one :manufacturer, graph_select: [:id, :name]

  dataset_module do
    order :by_name, :manufacturer_id, :name
    def options
      select(:id, :name, :disabled)
        .where(disabled: false)
        .eager_graph(:manufacturer, :device_type)
        .order(Sequel[:manufacturer][:name]).all
        .map do |row|
          { value: row.id, text: "#{row.manufacturer.name} #{row.name}", group: row.device_type.name }
        end
    end

    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([DEVICE_MODELS].[NAME]) LIKE upper(:s) OR upper([MANUFACTURER].[NAME]) LIKE upper(:s) OR upper([DEVICE_TYPE].[NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end

    def prepare
      select(:id, :name, :disabled).eager_graph(:manufacturer, :device_type).order(:disabled, Sequel[:device_type][:name], Sequel[:manufacturer][:name], :name)
    end
  end

  def validate
    validates_presence :device_type_id
    validates_presence :manufacturer_id
    validates_presence :name
  end

  def title
    "#{device_type.name} #{manufacturer.name} #{name}"
  end
  
  def totals
    Device.totals id
  end

end