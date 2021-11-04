class Device < Sequel::Model
  one_to_many :device_note, order: Sequel.desc(:created_at)
  many_to_one :device_model, graph_select: [:id, :name]
  many_to_one :place, graph_select: [:id, :name], eager: :ancestors
  one_to_many :event, conditions: {type_id: [0b0000, 0b0010, 0b0100, 0b0110, 0b1100, 0b1010, 0b1000]}, limit: 10, order: Sequel.desc(:id)
  one_to_many :cartridge, conditions: { status: "issued" }
  many_to_one :contract
  attr_accessor :type_id
  attr_accessor :contract_id
  attr_accessor :action
  attr_accessor :component
  attr_accessor :nodal

  ALLOWED_VIEWS_DEVICE = %w[reserved installed dismantled serviced written_off]

  dataset_module do
    order :by_code, :code
    def installed
      where(status: "installed")
    end

    def dismantled
      where(status: ["dismantled", "faulty"])
    end

    def serviced
      where(:status => "serviced")
    end

    def reserved
      where(:status => "reserved")
    end 
    
    def written_off
      where(:status => "written_off")
    end 

    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([CODE]) LIKE upper(:s) OR upper([PLACE].[NAME]) LIKE upper(:s) OR upper([DEVICE_TYPE].[NAME]) LIKE upper(:s) OR upper([MANUFACTURER].[NAME]) LIKE upper(:s) OR upper([DEVICE_MODEL].[NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end

    def prepare
      select(:id, :code, :status, :changed_at)
      .eager_graph(device_model: [:manufacturer, :device_type])
      .eager_graph(:place)
    end
  end

  def validate
    validates_presence :place_id
    validates_presence :code
    validates_unique   :code
    validates_presence :device_model_id
  end

  def self.find_all_grouped(view)
    return {} unless ALLOWED_VIEWS_DEVICE.include?(view)
    send(view).prepare
  end

  def before_create
    self.changed_at ||= Time.now
    super
  end

  def before_update
    return super unless self.type_id 
    self.changed_at = Time.now
    self.status = case self.type_id
    when 0b0110
      "reserved"
    when 0b0000
      "installed"
    when 0b0010
      "dismantled"
    when 0b1010
      "reserved"
    when 0b0100
      "serviced"
    when 0b1100
      "faulty"
    when 0b1000
      "written_off"
    end
    Event.insert({
      :device_id => self.id, 
      :type_id => self.type_id,
      :action => [self.nodal, self.component].map {|item| item ? 1 : 0  }.join.to_i(2),
      :contract_id => self.contract_id,
      :place_id => self.place_id,
      :created_at => Time.now
    })
    super
  end
  
  def title
    "#{type_name} #{model_name}"
  end

  def model_name
    "#{device_model.manufacturer.name} #{device_model.name}"
  end

  def type_name
    device_model.try(:device_type).try(:name)
  end

  def issued_count
    Cartridge.where(device_id: id, status: "issued").count if id
  end
end
