Sequel::Model.plugin :timestamps, :create => :created_at, :update => :updated_at, :update_on_create => true
Sequel::Model.plugin :validation_helpers
Sequel::Model.raise_on_save_failure = false




class Sequel::Model
  private
  def default_validation_helpers_options(type)
    case type
    when :presence
      {message: lambda{I18n.t("errors.presence")}}
    when :unique
      {message: lambda{I18n.t("errors.unique")}}
    when :type
      {message: lambda{|klass| klass.is_a?(Array) ? "is not a valid #{klass.join(" or ").downcase}" : "is not a valid #{klass.to_s.downcase}"}}
    else
      super
    end
  end
end

db_connection_params = {
  :adapter => 'tinytds',
  :host => '10.1.20.237',
  :port => '1433', 
  :database => 'databasename',
  :user => '',
  :password => ''
}

Sequel::Model.db = case RACK_ENV.to_s.downcase.to_sym
  when :development then Sequel.connect(db_connection_params,  :loggers => [Logger.new($stdout)])
  when :production  then Sequel.connect(db_connection_params)
  when :test        then Sequel.connect(db_connection_params,  :loggers => [Logger.new($stdout)])
end

