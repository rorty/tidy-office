class Compatibility < Sequel::Model
    many_to_one :cartridge
    many_to_one :device
end