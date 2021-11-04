class CartridgeNote < Sequel::Model
  many_to_one :cartridge
end
