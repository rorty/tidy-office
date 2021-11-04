class DeviceNote < Sequel::Model
  many_to_one :device
end
