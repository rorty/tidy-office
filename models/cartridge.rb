class Cartridge < Sequel::Model
  one_to_many :cartridge_note, order: Sequel.desc(:created_at)
  many_to_one :cartridge_model, graph_select: [:id, :name]
  many_to_one :device, graph_select: [:id]
  one_to_many :event, conditions: {type_id: [0b0001, 0b0011, 0b0101, 0b0111, 0b1101, 0b1011, 0b1001]}, limit: 10, order: Sequel.desc(:id)
    
  attr_accessor :type_id
  attr_accessor :contract_id
  attr_accessor :place_id
  attr_accessor :dosing_blade
  attr_accessor :mechanism_repair
  attr_accessor :clean
  attr_accessor :charge_roller
  attr_accessor :magnetic_shaft
  attr_accessor :chip
  attr_accessor :raquel
  attr_accessor :photo_drum
  attr_accessor :refill
  attr_accessor :init

  ALLOWED_VIEWS_CARTRIDGE = %w[reserved issued accepted serviced written_off]

  def before_create
    self.changed_at ||= Time.now
    super
  end

  def validate
    super
    validates_presence :cartridge_model_id
    validates_presence :code
    validates_unique :code 
    validates_presence :device_id if type_id == 0b0001
  end

  def before_update
    return super unless self.type_id 
    self.refill_count += 1 if self.refill
    self.changed_at = Time.now
    self.status = case self.type_id
    when 0b0111
      "reserved"
    when 0b0001
      "issued"
    when 0b0011
      "accepted"
    when 0b1011
      "reserved"
    when 0b0101
      "serviced"
    when 0b1101
      "faulty"
    when 0b1001
      "written_off"
    end  

    Event.insert({
      :cartridge_id => self.id, 
      :device_id => self.device_id, 
      :type_id => self.type_id,
      :action => [self.mechanism_repair, self.clean, self.dosing_blade, self.charge_roller, self.magnetic_shaft, self.chip, self.raquel, self.photo_drum, self.refill].map {|item| item ? 1 : 0  }.join.to_i(2),
      :contract_id => self.contract_id,
      :place_id => self.device.try(:place_id),
      :created_at => Time.now
    })
    super
  end

  dataset_module do
    order :by_code, :code
    def issued
      where(Sequel[:cartridges][:status] => "issued")
    end

    def accepted
      where(Sequel[:cartridges][:status] => ["accepted", "faulty"])
    end

    def serviced
      where(Sequel[:cartridges][:status] => "serviced")
    end

    def reserved
      where(Sequel[:cartridges][:status] => "reserved")
    end

    def written_off
      where(Sequel[:cartridges][:status] => "written_off")
    end

    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([CARTRIDGES].[CODE]) LIKE upper(:s) OR upper([PLACE].[NAME]) LIKE upper(:s) OR upper([CARTRIDGE_TYPE].[NAME]) LIKE upper(:s) OR upper([MANUFACTURER].[NAME]) LIKE upper(:s) OR upper([CARTRIDGE_MODEL].[NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end

    def prepare
      select(:id, :code, :status, :changed_at)
      .eager_graph(cartridge_model: [:manufacturer, :cartridge_type])
      .eager_graph(device: :place)
    end
  end

  def self.find_all_grouped(view)
    return {} unless ALLOWED_VIEWS_CARTRIDGE.include?(view)
    send(view).prepare
  end
  
  def title
    "#{type_name} #{model_name}"
  end

  def model_name
    "#{cartridge_model.manufacturer.name} #{cartridge_model.name}"
  end

  def type_name
    cartridge_model.cartridge_type.name
  end
end
