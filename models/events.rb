class Event < Sequel::Model
  many_to_one :device, graph_select: [:code]
  many_to_one :cartridge, graph_select: [:code]
  many_to_one :place, graph_select: [:id, :name]

  ALLOWED_VIEWS_EVENTS = %w[cartridges devices]

  dataset_module do
    def conditions_devices
      where(type_id: [0b0000, 0b0010, 0b0100, 0b0110, 0b1100, 0b1010, 0b1000])
    end
    def conditions_cartridges
      where(type_id: [0b0001, 0b0011, 0b0101, 0b0111, 0b1101, 0b1011, 0b1001])
    end
    def devices
      where(type_id: [0b0000, 0b0010, 0b0100, 0b0110, 0b1100, 0b1010, 0b1000])
    end
    def cartridges
      where(type_id: [0b0001, 0b0011, 0b0101, 0b0111, 0b1101, 0b1011, 0b1001])
    end
    def cartridges_filter ids
      where(cartridge_type_id: ids)
    end
    def devices_filter ids
      where(device_type_id: ids)
    end
    def prepare
      select(:place_id, :cartridge_id, :device_id, :type_id, :action, :created_at)
      .eager_graph([
        :place,
        cartridge: { cartridge_model: [Sequel[:manufacturer].as(:cartridge_manufacturer), :cartridge_type]},
        device: { device_model: [Sequel[:manufacturer].as(:device_manufacturer), :device_type] }])
      .order(Sequel.desc(:created_at))
    end

  end

  def self.report_for_devices
    sql = %{
      SELECT [ID],
            [0] AS [TO_INSTALL],
            [2] AS [TO_DISMANTLE],
            [4] AS [TO_SERVICE],
            [6] AS [FROM_SERVICE],
            [8] AS [TO_WRITE_OFF],
            [10] AS [TO_RESERVE],
            [12] AS [TO_FAULTY]
      FROM 
      (SELECT [EVENTS].[TYPE_ID],
            [DEVICE_MODEL].[ID]
      FROM [EVENTS] INNER
      JOIN [DEVICES] AS [DEVICE]
          ON ([DEVICE].[ID] = [EVENTS].[DEVICE_ID]) LEFT OUTER
      JOIN [DEVICE_MODELS] AS [DEVICE_MODEL]
          ON ([DEVICE_MODEL].[ID] = [DEVICE].[DEVICE_MODEL_ID])
      WHERE [EVENTS].[CREATED_AT] >= CAST(DATEADD(YY, -1, GETDATE()) AS DATE) 
      ) AS MAIN PIVOT (COUNT([TYPE_ID]) FOR [TYPE_ID] IN ([0], [2], [4], [6], [8], [10], [12])) AS PIVOTTABLE;
    }
    fetch(sql)
  end

  def self.report_for_cartridges
    sql = %{
      SELECT [ID],
            [1] AS [TO_ISSUE],
            [3] AS [TO_ACCEPT],
            [5] AS [TO_SERVICE],
            [7] AS [FROM_SERVICE],
            [9] AS [TO_WRITE_OFF],
            [11] AS [TO_RESERVE],
            [13] AS [TO_FAULTY]
      FROM 
      (SELECT [EVENTS].[TYPE_ID],
            [CARTRIDGE_MODEL].[ID]
      FROM [EVENTS] INNER
      JOIN [CARTRIDGES] AS [CARTRIDGE]
          ON ([CARTRIDGE].[ID] = [EVENTS].[CARTRIDGE_ID]) LEFT OUTER
      JOIN [CARTRIDGE_MODELS] AS [CARTRIDGE_MODEL]
          ON ([CARTRIDGE_MODEL].[ID] = [CARTRIDGE].[CARTRIDGE_MODEL_ID])
      WHERE [EVENTS].[CREATED_AT] >= CAST(DATEADD(YY, -1, GETDATE()) AS DATE) 
      ) AS MAIN PIVOT (COUNT([TYPE_ID]) FOR [TYPE_ID] IN ([1], [3], [5], [7], [9], [11], [13])) AS PIVOTTABLE;
    }
    fetch(sql)
  end


  def self.find_all_grouped(view)
    return {} unless ALLOWED_VIEWS_EVENTS.include?(view)
    send(view).prepare
  end

  def self.event_devices(devices)
    prepare.devices.where(Sequel[:events][:device_id] => devices).all
  end


  def self.events
    limit(15).order(Sequel.desc(:id)).eager_graph([:place, :cartridge => {:cartridge_model => [:manufacturer, :cartridge_type]}, :device => {:device_model => [:manufacturer, :device_type]}])
  end
  
  def self.event_cartridges(cartridges)
    prepare.cartridges.where(cartridge_id: cartridges).all
  end
end
