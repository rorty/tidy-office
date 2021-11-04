class Contract < Sequel::Model
  
  def validate
    validates_presence :name
  end
  def enabled?
    
  end
  def title
    "#{name}"
  end
end
