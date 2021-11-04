module CartridgeManagement
  class Application < Sinatra::Base
    configure do
      set :views, File.join(APP_ROOT, 'apps/views')
    end

    def cartridge_total
      all = {}
      totals = { title: "Итого", total: { count: 0, reserved: 0, issued: 0, accepted: 0, serviced: 0, faulty: 0}}
      CartridgeModel.order(Sequel[:cartridge_type][:name], Sequel[:manufacturer][:name], :name).eager_graph(:manufacturer, :cartridge_type).all.each do |item|
        all[item.id] = { title: item.title, total: { count: 0, reserved: 0, issued: 0, accepted: 0, serviced: 0, faulty: 0}}
      end
      %w[reserved issued accepted serviced faulty].each do |key|
       Cartridge.where(:status => key).group_and_count(:cartridge_model_id).all.each do |item| 
         all[item.cartridge_model_id][:total][key.to_sym] = item[:count]
         all[item.cartridge_model_id][:total][:count] += item[:count]
         totals[:total][key.to_sym] += item[:count]
         totals[:total][:count] += item[:count]
       end
     end
     all.map{|a| a.last} << totals
    end

    def cartridge_total2
      all = {}
      totals = { title: "Итого", total: { to_issue: 0, to_accept: 0, to_service: 0, from_service: 0, to_write_off: 0, to_reserve: 0, to_faulty: 0}}
      CartridgeModel.order(Sequel[:cartridge_type][:name], Sequel[:manufacturer][:name], :name).eager_graph(:manufacturer, :cartridge_type).all.each do |item|
        all[item.id] = { title: item.title, total: { to_issue: 0, to_accept: 0, to_service: 0, from_service: 0, to_write_off: 0, to_reserve: 0, to_faulty: 0}}
      end
      Event.report_for_cartridges.all do |row|
        %w[to_issue to_accept to_service from_service to_write_off to_reserve to_faulty].each do |key|
          all[row[:id]][:total][key.to_sym] = row[key.to_sym]
          totals[:total][key.to_sym] += row[key.to_sym]
        end
      end
     all.map{|a| a.last} << totals
    end

    def device_total
      all = {}
      totals = { title: "Итого", total: { count: 0, reserved: 0, installed: 0, dismantled: 0,  serviced: 0, faulty: 0 }}
      DeviceModel.order(Sequel[:device_type][:name], Sequel[:manufacturer][:name], :name).eager_graph(:manufacturer, :device_type).all.each do |item|
        all[item.id] = { title: item.title, total: { count: 0, reserved: 0, installed: 0, dismantled: 0, serviced: 0, faulty: 0 }}
      end
      %w[reserved installed dismantled serviced faulty].each do |key|
        Device.where(:status => key).group_and_count(:device_model_id).all.each do |item| 
          all[item.device_model_id][:total][key.to_sym] = item[:count]
          all[item.device_model_id][:total][:count] += item[:count]
          totals[:total][key.to_sym] += item[:count]
          totals[:total][:count] += item[:count]
        end
      end
      all.map{|a| a.last} << totals
    end

    def device_total2
      all = {}
      totals = { title: "Итого", total: { to_install: 0, to_dismantle: 0, to_service: 0, from_service: 0, to_write_off: 0, to_reserve: 0, to_faulty: 0}}
      DeviceModel.order(Sequel[:device_type][:name], Sequel[:manufacturer][:name], :name).eager_graph(:manufacturer, :device_type).all.each do |item|
        all[item.id] = { title: item.title, total: { to_install: 0, to_dismantle: 0, to_service: 0, from_service: 0, to_write_off: 0, to_reserve: 0, to_faulty: 0}}
      end
      Event.report_for_devices.all do |row|
        %w[to_install to_dismantle to_service from_service to_write_off to_reserve to_faulty].each do |key|
          all[row[:id]][:total][key.to_sym] = row[key.to_sym]
          totals[:total][key.to_sym] += row[key.to_sym]
        end
      end
     all.map{|a| a.last} << totals
    end

    def windowed_page_numbers(current_page, total_pages)
      inner_window, outer_window = 5, 1
      window_from = current_page - inner_window
      window_to = current_page + inner_window
      if window_to > total_pages
        window_from -= window_to - total_pages
        window_to = total_pages
      end
      if window_from < 1
        window_to += 1 - window_from
        window_from = 1
        window_to = total_pages if window_to > total_pages
      end
      middle = window_from..window_to
      if outer_window + 3 < middle.first
        left = (1..(outer_window + 1)).to_a
        left << :gap
      else
        left = 1...middle.first
      end
      if total_pages - outer_window - 2 > middle.last
        right = ((total_pages - outer_window)..total_pages).to_a
        right.unshift :gap
      else
        right = (middle.last + 1)..total_pages
      end
      left.to_a + middle.to_a + right.to_a
      middle.to_a
    end

    def build_query(params)
      Rack::Utils.build_nested_query params
    end
    
    def view_cartridge
      view = params[:view]
      views = Cartridge::ALLOWED_VIEWS_CARTRIDGE
      views.include?(view) ? view : views.first
    end

    def view_device
      view = params[:view]
      views = Device::ALLOWED_VIEWS_DEVICE
      views.include?(view) ? view : views.first
    end

    def view_report
      view = params[:view]
      views = %w[cartridges devices]
      views.include?(view) ? view : views.first
    end

    def view_event
      view = params[:view]
      views = Event::ALLOWED_VIEWS_EVENTS
      views.include?(view) ? view : views.first
    end 

    def tree(place, &block)
      raise ArgumentError, "Missing block" unless block_given?
      return until place.children.present?
      capture_haml do
        haml_tag :ul, capture_haml { place.children.inject([]) do |all, children|
          all << capture_haml do
            haml_tag :li, capture_haml { yield(children) << tree(children, &block).to_s }, class: "item"
          end
        end.join("\n").html_safe }
      end
    end

    def tree2(place, &block)
      raise ArgumentError, "Missing block" unless block_given?
      return until place.children.present?
      place.children.inject([]) do |all, children|
        all << yield(children)
      end
    end

    def render_tree child, children
      lines = [["", child]]
      children.each_with_index do |child, index|
        child_lines = render_tree(child, child.children) 
        if index < children.size - 1
          child_lines.each_with_index do |(prefix, target), idx|
            lines << [ (idx == 0) ? "├─ " : "|  " << prefix, target ] 
          end
        else
          child_lines.each_with_index do |(prefix, target), idx|
            lines << [ (idx == 0) ? "└─ " : "   " << prefix, target ] 
          end
        end
      end
      lines
    end

    before do
      protected! if request.request_method != "GET"
    end

    get "/" do
      redirect(to("cartridges"))
    end

    def update_session name
      filters = (session[name].nil? ? [] : session[name].split(","))
      yield filters 
      session[name] = filters.uniq.join(",")
    end

    namespace '/events' do
      get do
        @view = view_event
        @type, @types = case @view.to_sym
        when :cartridges
          [ :cartridges_filter, CartridgeType.order(:name).all ]
        when :devices
          [ :devices_filter, DeviceType.order(:name).all ]
        end
        @events = get_events

        respond_to do |f|
          f.js   { haml :"events/index.js", :layout => false }
          f.html { haml :"events/index" }
        end
      end

      post '/filter' do
        @view = view_event
        @type = case @view.to_sym
        when :cartridges
          :cartridges_filter
        when :devices
          :devices_filter
        end
        update_session(@type) do |filters|
          if params[:checked] == "true"
            filters << params[:filter]
          else
            filters.delete(params[:filter])
          end
        end
        @events = get_events
        respond_to do |format|
          format.js { haml :"events/index.js", :layout => false }
        end
      end      
    end

    namespace '/reports' do
      get do
        redirect(to("reports/1"))
      end
      get "/:id" do
        @totals, @action = case params[:id].to_i
        when 1
          [cartridge_total, %w[reserved issued accepted serviced faulty count]]
        when 2
          [device_total, %w[reserved installed dismantled serviced faulty count]]
        when 3
          [cartridge_total2, %w[to_issue to_accept to_service from_service to_write_off to_reserve to_faulty]]
        when 4
          [device_total2, %w[to_install to_dismantle to_service from_service to_write_off to_reserve to_faulty]]
        end
        haml :"reports/index"
      end
    end

    namespace '/devices' do
      get do
        @devices = get_devices
        @types = DeviceType.order(:name).all

        respond_to do |f|
          f.js   { haml :"devices/index.js", :layout => false }
          f.html { haml :"devices/index" }
        end
      end

      post '/filter' do
        update_session(:devices_filter) do |filters|
          if params[:checked] == "true"
            filters << params[:filter]
          else
            filters.delete(params[:filter])
          end
        end
        @devices = get_devices
        respond_to do |format|
          format.js { haml :"devices/index.js", :layout => false }
        end
      end    

      get '/new' do
        @device = Device.new
        @places = Place.select(:id, :name, :description).where(disabled: false, warehouse: true).order(:name)
        @device_models = DeviceModel.options
        haml :"devices/new"
      end

      post '/create' do
        @device = Device.new(params[:device])
        if (@device.save rescue false)
          flash[:success] = t(:create_success, model: t(:device))
          redirect(to("devices"))
        else
          @places = Place.select(:id, :name, :description).where(disabled: false, warehouse: true).order(:name)
          @device_models = DeviceModel.options
          flash.now[:error] = t(:create_error, model: t(:device))
          haml :"devices/new"
        end
      end

      put '/update/:id' do
        @device = Device[params[:id]]
        if @device
          if @device.modified! && @device.update(params[:device])
            flash[:success] = t(:update_success, model: t(:device), id: @device.id)
            redirect(to("devices/show/#{@device.id}"))
          else
            @places = Place.select(:id, :name, :description).where(disabled: false).order(:name)
            @device_models = DeviceModel.options
            flash.now[:error] = t(:update_error, model: t(:device))
            haml :"devices/edit"
          end
        else
          halt 404
        end
      end

      get '/edit/:id' do
        @device = Device[params[:id]]
        @places = Place.select(:id, :name, :description).where(disabled: false).order(:name)
        @device_models = DeviceModel.options
        
        if @device
          haml :"devices/edit"
        else
          halt 404
        end
      end

      get '/show/:id' do
        @device = Device[params[:id]]
        @services = Event.where(device_id: params[:id], type_id: 0b0110)
        if @device
          @note = DeviceNote.new
          haml :"devices/show"
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        device = Device[params[:id]]
        if device
          if (device.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:device), id: device.id)
          else
            flash[:error] = t(:delete_error, model: t(:device))
          end
          redirect to("devices")
        else
          halt 404
        end
      end

      get "/current_device" do 
        @devices = Device.prepare.where(:place_id => params[:place][:place_id], status: "installed" ).all
        respond_to do |f|
          f.js   { haml :"devices/current_device.js", :layout => false }
        end
      end
      
      get '/to_install' do
        redirect(to("devices")) if params[:device_ids].blank?
        @places = Place.prepare
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        haml :"devices/to_install"
      end
 
      put '/to_install' do
        ids = params[:device_ids].split(',').map(&:strip)
        @devices = Device.where(:id => ids).all
        @devices.reject! do |device|
          !unless device.modified! && device.update(:place_id => params[:place][:place_id], :type_id => 0b0000)
            device.refresh
          end
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: ids.join(","))
          redirect(to("devices?view=installed"))
        else
          @places = Place.select(:id, :name, :description).where(disabled: false).order(:name)
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/to_install"
        end
      end
      
      get '/to_reserve' do
        redirect(to("devices")) if params[:device_ids].blank?
        @places = Place.select(:id, :name, :description).where(warehouse: true).order(:name)
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        haml :"devices/to_reserve" 
      end
 
      put '/to_reserve' do
        ids = params[:device_ids].split(',').map(&:strip)
        @devices = Device.where(:id => ids).all
        @devices.reject! do |device|
          !unless device.modified! && device.update(:place_id => params[:place][:place_id], :type_id => 0b1010)
            device.refresh
          end
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: ids.join(","))
          redirect(to("devices?view=reserved"))
        else
          @places = Place.select(:id, :name, :description).where(warehouse: true).order(:name)
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/to_reserve"
        end
      end

      get '/to_dismantle' do
        redirect(to("devices")) if params[:device_ids].blank?
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        haml :"devices/to_dismantle"   
      end

      put '/to_dismantle' do
        ids = params[:device_ids].split(',').map(&:strip)
        @devices = Device.where(:id => ids).all
        @devices.reject! do |device|
          !unless device.modified! && device.update(:type_id => 0b0010)
            device.refresh
          end
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: ids.join(","))
          redirect(to("devices?view=dismantled"))
        else
          
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/to_dismantle"
        end      
      end

      get '/to_write_off' do
        redirect(to("devices")) if params[:device_ids].blank?
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        @places = Place.select(:id, :name, :description).where(warehouse: true).order(:name)
        haml :"devices/to_write_off"   
      end  

      put '/to_write_off' do
        ids = params[:device_ids].split(',').map(&:strip)
        @devices = Device.where(:id => ids).all
        @devices.reject! do |device|
          device.modified! && device.update(:type_id => 0b1000)
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: ids.join(","))
          redirect(to("devices?view=written_off"))
        else
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/to_write_off"
        end      
      end

      get '/to_faulty' do
        redirect(to("devices")) if params[:device_ids].blank?
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        haml :"devices/to_faulty"  
      end

      put '/to_faulty' do
        ids = params[:device_ids].split(',').map(&:strip)
        @devices = Device.where(:id => ids).all
        @devices.reject! do |device|
          device.modified! && device.update(:type_id => 0b1100)
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: ids.join(","))
          redirect(to("devices?view=dismantled"))
        else
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/to_faulty"
        end    
      end
      
      get '/to_print' do
        content_type 'application/pdf'
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all.map do |item|
          [item.type_name, item.model_name, item.code]
        end
        pdf = Prawn::Document.new({ :left_margin => 10.mm, :top_margin => 10.mm, :bottom_margin => 10.mm, :margin => 10.mm, :page_size => "A4" })
        pdf.font_families.update(
        "Consolas" => {
          :bold => "consolab.ttf",
          :italic => "consolai.ttf",
          :normal  => "consola.ttf" })
        pdf.font("Consolas", :style => :italic)
          @devices.each_with_index do |item, index| 
            barcode = Barby::Code128A.new(item[2])
            outputter = Barby::PrawnOutputter.new(barcode)
            pdf.bounding_box([45.mm + (index % 2) * 50.mm, pdf.bounds.top - 30.mm * (index / 2)], :width => 50.mm, :height => 30.mm) do
                pdf.bounding_box([3, pdf.bounds.top], :width => 5.mm,:height => pdf.bounds.top) do
                  pdf.svg IO.read("logo1.svg"), :position => :left
                end
                pdf.bounding_box([5.mm, pdf.bounds.top], width: 45.mm, height: 20.mm) do
                    pdf.text_box "#{item[0]}\n#{item[1]}", :at => [0, pdf.cursor], :align => :center, :valign => :center
                end
                pdf.bounding_box([5.mm, pdf.bounds.top - 20.mm], :width => 45.mm, :height => pdf.bounds.top) do
                    pdf.move_down 3
                    outputter.annotate_pdf pdf, height: 15, :x => (pdf.bounds.width / 2) - (outputter.width / 2), :y => pdf.cursor - 12, :xdim => 1
                    pdf.move_down 13
                    pdf.text_box item[2], :at => [0, pdf.cursor], :align => :center
                end
                pdf.transparent(0.05) {  pdf.stroke_bounds }         
            end
        end 
        pdf.render
      end

      get '/to_service' do
        redirect(to("devices")) if params[:device_ids].blank?
        @contracts = Contract.where(:enabled => true).all
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        haml :"devices/to_service"  
      end

      put '/to_service' do
        ids = params[:device_ids].split(',').map(&:strip)
        @devices = Device.where(:id => ids).all
        @devices.reject! do |device|
          device.modified! && device.update(:type_id => 0b0100, :contract_id => params[:contract][:contract_id].presence)
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: ids.join(","))
          redirect(to("devices?view=serviced"))
        else
          @contracts = Contract.where(:enabled => true).all
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/to_service"
        end    
      end

      get '/from_service' do
        redirect(to("devices")) if params[:device_ids].blank?
        @contracts = Contract.where(:enabled => true).all
        @devices = Device.where(Sequel[:devices][:id] => params[:device_ids].split(',').map(&:strip)).prepare.all
        haml :"devices/from_service"  
      end

      put '/from_service' do
        @devices = Device.where(:id => params[:devices].keys).all
        @devices.reject!.with_index do |device, index|
          device.modified! && device.update(params[:devices].values[index].merge(:type_id => 0b0110, :contract_id => params[:contract_id].blank? ?  nil : params[:contract_id]).except!(:init))
        end
        if @devices.empty?
          flash[:success] = t(:update_success, model: t(:device), id: params[:devices].keys.join(","))
          redirect(to("devices?view=reserved"))
        else
          @contracts = Contract.where(:enabled => true).all
          flash.now[:error] = t(:update_error, model: t(:device))
          haml :"devices/from_service"
        end
      end
    end

    namespace '/device_notes' do
      post do
        @note = DeviceNote.new(params[:note])
        respond_to do |format|
          if @note.save
            format.js { haml :"device_notes/create.js", :layout => false }
          end
        end
      end   
      
      put "/:id" do
        @note = DeviceNote[params[:id]]
        respond_to do |format|
          if @note.modified! && @note.update(params[:note])
            format.js { haml :"device_notes/update.js", :layout => false }
          end
        end
      end


      get '/edit/:id' do
        @note = DeviceNote[params[:id]]
        if @note
          respond_to do |f|
            f.js   { haml :"device_notes/edit.js", :layout => false }
          end
        else
          halt 404
        end
      end

      delete '/destroy/:id' do
        @note = DeviceNote[params[:id]]
        if @note
          if (@note.destroy rescue false)
            respond_to do |f|
              f.js   { haml :"device_notes/destroy.js", :layout => false }
            end
          end
        else
          halt 404
        end
      end 
    end
 
    namespace '/cartridges' do
      get do
        @cartridges = get_cartridges(page: page_param)
        respond_to do |f|
          f.js   { haml :"cartridges/index.js", :layout => false }
          f.html { haml :"cartridges/index" }
        end
      end

      post '/filter' do
        update_session(:cartridges_filter) do |filters|
          if params[:checked] == "true"
            filters << params[:filter]
          else
            filters.delete(params[:filter])
          end
        end
        @cartridges = get_cartridges(page: page_param)
        respond_to do |format|
          format.js { haml :"cartridges/index.js", :layout => false }
        end
      end    

      get '/new' do
        @cartridge = Cartridge.new
        @cartridge_models = CartridgeModel.options
        haml :"cartridges/new"
      end

      post "/create" do
        @cartridge = Cartridge.new(params[:cartridge])
        if (@cartridge.save rescue false)
          flash[:success] = t(:create_success, model: t(:cartridge))
          redirect(to("cartridges"))
        else
          @cartridge_models = CartridgeModel.options
          flash.now[:error] = t(:create_error, model: t(:cartridge))
          haml :"cartridges/new"
        end
      end

      put '/update/:id' do
        @cartridge = Cartridge[params[:id]]
        if @cartridge
          if @cartridge.modified! && @cartridge.update(params[:cartridge])
            flash[:success] = t(:update_success, model: t(:cartridge), id: @cartridge.id)
            redirect(to("cartridges/show/#{@cartridge.id}"))
          else
            @cartridge_models = CartridgeModel.options.all
            flash.now[:error] = t(:update_error, model: t(:cartridge))
            haml :"cartridges/edit"
          end
        else
          halt 404
        end
      end

      get '/edit/:id' do
        @cartridge = Cartridge[params[:id]]
        @cartridge_models = CartridgeModel.options
        if @cartridge
          haml :"cartridges/edit"
        else
          halt 404
        end
      end

      get '/show/:id' do
        @cartridge = Cartridge[params[:id]]
        @services = Event.where(cartridge_id: params[:id], type_id: 0b0111)
        if @cartridge
          @note = DeviceNote.new
          haml :"cartridges/show"
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        cartridge = Cartridge[params[:id]]
        if cartridge
          if (cartridge.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:cartridge), id: cartridge.id)
          else
            flash[:error] = t(:delete_error, model: t(:cartridge))
          end
          redirect to("cartridges")
        else
          halt 404
        end
      end

      get "/current_cartridge" do 
        @cartridges = Cartridge.prepare.where(:device_id => params[:cartridge][:device_id], Sequel[:cartridges][:status] => "issued").all
        respond_to do |f|
          f.js   { haml :"cartridges/current_cartridge.js", :layout => false }
        end
      end

      get "/current_device" do 
        @devices = Device.prepare
          .where(status: "installed", compatibility: true, :place_id => params[:cartridge][:place_id]).all
        respond_to do |f|
          f.js   { haml :"cartridges/current_device.js", :layout => false }
        end
      end
      
      get '/to_issue' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @places = Place.select(:id, :name, :description).where(disabled: false).order(:name)
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/to_issue"
      end
 
      put '/to_issue' do
        ids = params[:cartridge_ids].split(',').map(&:strip)
        @cartridges = Cartridge.where(:id => ids).all
        @cartridges.reject! do |cartridge|
          cartridge.modified! && cartridge.update(params[:cartridge].merge(:type_id => 0b0001))
        end
        if @cartridges.empty?
          flash[:success] = t(:update_success, model: t(:cartridge), id: ids.join(","))
          params[:return_cartridge_ids] ? 
            redirect(to("cartridges/to_accept?cartridge_ids=#{escape_html(params[:return_cartridge_ids].join(","))}")) :
            redirect(to("cartridges?view=issued"))
        else
          @places = Place.select(:id, :name, :description).where(disabled: false).order(:name)
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/to_issue"
        end
      end
      
      get '/to_reserve' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/to_reserve"   
      end
 
      put '/to_reserve' do
        ids = params[:cartridge_ids].split(',').map(&:strip)
        @cartridges = Cartridge.where(:id => ids).all
        @cartridges.reject! do |cartridge|
          cartridge.modified! && cartridge.update(device_id: nil, :type_id => 0b1011)
        end
        if @cartridges.empty?
          flash[:success] = t(:update_success, model: t(:cartridge), id: ids.join(","))
          redirect(to("cartridges?view=reserved"))
        else
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/to_reserve"
        end
      end

      get '/to_accept' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/to_accept" 
      end

      put '/to_accept' do
        ids = params[:cartridge_ids].split(',').map(&:strip)
        @cartridges = Cartridge.where(:id => ids).all
        @cartridges.reject! do |cartridge|
          cartridge.modified! && cartridge.update(:type_id => 0b0011)
        end
        if @cartridges.empty?
          flash[:success] = t(:update_success, model: t(:cartridge), id: ids.join(","))
          redirect(to("cartridges?view=accepted"))
        else
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/to_accept"
        end
      end

      get '/to_faulty' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/to_faulty"
      end

      put '/to_faulty' do
        ids = params[:cartridge_ids].split(',').map(&:strip)
        @cartridges = Cartridge.where(id: ids).all
        @cartridges.reject! do |cartridge|
          cartridge.modified! && cartridge.update(:device_id => nil, :type_id => 0b1101)
        end
        if @cartridges.empty?
          flash[:success] = t(:update_success, model: t(:cartridge), id: ids.join(","))
          redirect(to("cartridges?view=accepted"))
        else
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/to_accept"
        end
      end

      get '/to_write_off' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/to_write_off"
      end

      put '/to_write_off' do
        @cartridges = Cartridge.where(:id => params[:cartridge_ids].split(',').map(&:strip)).all
        @cartridges.reject! do |cartridge|
          cartridge.modified! && cartridge.update(:device_id => nil, :type_id => 0b1001)
        end
        if @cartridges.empty?
          redirect(to("cartridges?view=written_off"))
        else
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/to_write_off"
        end
      end

      get '/to_service' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @contracts = Contract.where(:enabled => true).all
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/to_service" 
      end

      put '/to_service' do
        ids = params[:cartridge_ids].split(',').map(&:strip)
        @cartridges = Cartridge.where(:id => ids).all
        @cartridges.reject! do |cartridge|
          cartridge.modified! && cartridge.update(device_id: nil, :type_id => 0b0101, :contract_id => params[:contract][:contract_id].presence)
        end
        if @cartridges.empty?
          flash[:success] = t(:update_success, model: t(:cartridge), id: ids.join(","))
          redirect(to("cartridges?view=serviced"))
        else
          @contracts = Contract.where(:enabled => true).all
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/to_service"
        end
      end

      get '/from_service' do
        redirect(to("cartridges")) if params[:cartridge_ids].blank?
        @contracts = Contract.where(:enabled => true).all
        @cartridges = Cartridge.where(Sequel[:cartridges][:id] => params[:cartridge_ids].split(',').map(&:strip)).prepare.all
        haml :"cartridges/from_service" 
      end

      put '/from_service' do
        @cartridges = Cartridge.where(:id => params[:cartridges].keys).all
        @cartridges.reject!.with_index do |cartridge, index|
          cartridge.modified! && cartridge.update(params[:cartridges].values[index].merge(:type_id => 0b0111, :contract_id => params[:contract_id].presence ))
        end
        if @cartridges.empty?
          flash[:success] = t(:update_success, model: t(:cartridge), id: params[:cartridges].keys.join(","))
          redirect(to("cartridges?view=reserved"))
        else
          @contracts = Contract.where(:enabled => true).all
          flash.now[:error] = t(:update_error, model: t(:cartridge))
          haml :"cartridges/from_service"
        end
      end

      get '/to_print' do
        content_type 'application/pdf'
        @cartridges = Cartridge.where(:id => params[:cartridge_ids].split(',').map(&:strip)).all.map do |item|
          [item.type_name, item.model_name, item.code]
        end
        pdf = Prawn::Document.new({ :left_margin => 10.mm, :top_margin => 10.mm, :bottom_margin => 10.mm, :margin => 10.mm, :page_size => "A4" })
        pdf.font_families.update(
          "Consolas" => {
            :bold => "consolab.ttf",
            :italic => "consolai.ttf",
            :normal  => "consola.ttf" })
        pdf.font("Consolas", :style => :italic)
        @cartridges.each_with_index do |item, index| 
            barcode = Barby::Code128A.new(item[2])
            outputter = Barby::PrawnOutputter.new(barcode)        
            pdf.bounding_box([50.mm, pdf.bounds.top - 10.mm * index], :width => 90.mm, :height => 10.mm) do
                pdf.bounding_box([0, pdf.bounds.top], :width => 20.mm, :height => pdf.bounds.top) do 
                    pdf.svg IO.read("logo2.svg"), :position => :center, :vposition => :top, :height => 4.mm, :width => 18.mm
                end
                pdf.bounding_box([20.mm, pdf.bounds.top], :width => 35.mm, :height => pdf.bounds.top) do
                    pdf.move_down 3
                    pdf.text_box item[0], :at => [0, pdf.cursor], :align => :center
                    pdf.move_down 13
                    pdf.text_box item[1], :at => [0, pdf.cursor], :align => :center#, :size => 8
                end
                pdf.bounding_box([55.mm, pdf.bounds.top], :width => 35.mm, :height => pdf.bounds.top) do
                    pdf.move_down 3
                    outputter.annotate_pdf pdf, height: 12, :x => (pdf.bounds.width / 2) - (outputter.width / 2), :y => pdf.cursor - 12, :xdim => 1
                    pdf.move_down 13
                    pdf.text_box item[2], :at => [0, pdf.cursor], :align => :center
                end
                pdf.transparent(0.05) {  pdf.stroke_bounds }         
            end
        end 
        pdf.render
      end

    end

    namespace '/cartridge_notes' do
      post do
        @note = CartridgeNote.new(params[:note])
        respond_to do |format|
          if @note.save
            format.js { haml :"cartridge_notes/create.js", :layout => false }
          end
        end
      end   
      
      put "/:id" do
        @note = CartridgeNote[params[:id]]
        respond_to do |format|
          if @note.modified! && @note.update(params[:note])
            format.js { haml :"cartridge_notes/update.js", :layout => false }
          end
        end
      end


      get '/edit/:id' do
        @note = CartridgeNote[params[:id]]
        if @note
          respond_to do |f|
            f.js   { haml :"cartridge_notes/edit.js", :layout => false }
          end
        else
          halt 404
        end
      end

      delete '/destroy/:id' do
        @note = CartridgeNote[params[:id]]
        if @note
          if (@note.destroy rescue false)
            respond_to do |f|
              f.js   { haml :"cartridge_notes/destroy.js", :layout => false }
            end
          end
        else
          halt 404
        end
      end 
    end

    namespace '/places' do
      get do
        @places = get_places
        respond_to do |f|
          f.js   { haml :"places/index.js", :layout => false }
          f.html { haml :"places/index" }
        end
      end

      get "/tree" do
        @places = Place.prepare.roots
        haml :"places/tree"
      end 

      get "/new" do
        @place = Place.new
        haml :"places/new"
      end

      post "/create" do
        @place = Place.new(params[:place])
        if (@place.save rescue false)
          flash[:success] = t(:create_success, model: t(:place))
          redirect(to("places")) 
        else
          flash.now[:error] = t(:create_error, model: t(:place))
          haml :"places/new"
        end
      end

      get "/edit/:id" do
        @place = Place[params[:id]]
        if @place
          haml :"places/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @place = Place[params[:id]]
        if @place
          if @place.modified! && @place.update(params[:place])
            flash[:success] = t(:update_success, model: t(:place), id: @place.id)
            redirect(to("places"))
          else
            flash.now[:error] = t(:update_error, model: t(:place))
            haml :"places/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        place = Place[params[:id]]
        if place
          if (place.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:place), id: place.id)
          else
            flash[:error] = t(:delete_error, model: t(:place))
          end
          redirect to("places")
        else
          halt 404
        end
      end

      get '/show/:id' do
        @place = Place[params[:id]]
        @devices = Device.prepare.where(place_id: [@place.descendants.map(&:id), @place.id].flatten, status: "installed").order(Sequel[:device_type][:name], Sequel[:manufacturer][:name], Sequel[:device_model][:name]).all 
        @cartridges = Cartridge.prepare.where(place_id: [@place.descendants.map(&:id), @place.id].flatten, Sequel[:cartridges][:status] => "issued").order(Sequel[:cartridge_type][:name], Sequel[:manufacturer][:name], Sequel[:cartridge_model][:name]).all  
        if @place
          haml :"places/show"
        else
          halt 404
        end
      end

    end

    namespace '/cartridge_models' do
      get do
        @cartridge_models = get_cartridge_models
        respond_to do |f|
          f.js   { haml :"cartridge_models/index.js", :layout => false }
          f.html { haml :"cartridge_models/index" }
        end
      end

      get "/new" do
        @manufacturers = Manufacturer.all
        @cartridge_types = CartridgeType.all
        @cartridge_model = CartridgeModel.new
        haml :"cartridge_models/new"
      end

      post "/create" do
        @cartridge_model = CartridgeModel.new(params[:cartridge_model])
        if (@cartridge_model.save rescue false)
          flash[:success] = t(:create_success, model: t(:cartridge_model))
          redirect(to("cartridge_models")) 
        else
          @manufacturers = Manufacturer.all
          @cartridge_types = CartridgeType.all
          flash.now[:error] = t(:create_error, model: t(:cartridge_model))
          haml :"cartridge_models/new"
        end
      end

      get "/edit/:id" do
        @cartridge_model = CartridgeModel[params[:id]]
        if @cartridge_model
          @manufacturers = Manufacturer.all
          @cartridge_types = CartridgeType.all
          haml :"cartridge_models/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @cartridge_model = CartridgeModel[params[:id]]
        if @cartridge_model
          if @cartridge_model.modified! && @cartridge_model.update(params[:cartridge_model])
            flash[:success] = t(:update_success, model: t(:cartridge_model), id: @cartridge_model.id)
            redirect(to("cartridge_models"))
          else
            @manufacturers = Manufacturer.all
            @cartridge_types = CartridgeType.all
            flash.now[:error] = t(:update_error, model: t(:cartridge_model))
            haml :"cartridge_models/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        cartridge_model = CartridgeModel[params[:id]]
        if cartridge_model
          if (cartridge_model.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:cartridge_model), id: cartridge_model.id)
          else
            flash[:error] = t(:delete_error, model: t(:cartridge_model))
          end
          redirect to("cartridge_models")
        else
          halt 404
        end
      end
    end

    namespace '/device_models' do
      get do
        @device_models = get_device_models
        respond_to do |f|
          f.js   { haml :"device_models/index.js", :layout => false }
          f.html { haml :"device_models/index" }
        end
      end

      get "/new" do
        @manufacturers = Manufacturer.all
        @device_types = DeviceType.all
        @device_model = DeviceModel.new
        haml :"device_models/new"
      end

      post "/create" do
        @device_model = DeviceModel.new(params[:device_model])
        if (@device_model.save rescue false)
          flash[:success] = t(:create_success, model: t(:device_model))
          redirect(to("device_models")) 
        else
          @manufacturers = Manufacturer.all
          @device_types = DeviceType.all
          flash.now[:error] = t(:create_error, model: t(:device_model))
          haml :"device_models/new"
        end
      end

      get "/edit/:id" do
        @device_model = DeviceModel[params[:id]]
        if @device_model
          @manufacturers = Manufacturer.all
          @device_types = DeviceType.all          
          haml :"device_models/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @device_model = DeviceModel[params[:id]]
        if @device_model
          if @device_model.modified! && @device_model.update(params[:device_model])
            flash[:success] = t(:update_success, model: t(:device_model), id: @device_model.id)
            redirect(to("device_models"))
          else
            @manufacturers = Manufacturer.all
            @device_types = DeviceType.all
            flash.now[:error] = t(:update_error, model: t(:device_model))
            haml :"device_models/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        device_model = DeviceModel[params[:id]]
        if device_model
          if (device_model.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:device_model), id: device_model.id)
          else
            flash[:error] = t(:delete_error, model: t(:device_model))
          end
          redirect to("device_models")
        else
          halt 404
        end
      end
    end

    namespace '/manufacturers' do
      get do
        @manufacturers = get_manufacturers
        respond_to do |f|
          f.js   { haml :"manufacturers/index.js", :layout => false }
          f.html { haml :"manufacturers/index" }
        end
      end

      get "/new" do
        @manufacturer = Manufacturer.new
        haml :"manufacturers/new"
      end

      post "/create" do
        @manufacturer = Manufacturer.new(params[:manufacturer])
        if (@manufacturer.save rescue false)
          flash[:success] = t(:create_success, model: t(:manufacturer))
          redirect(to("manufacturers")) 
        else
          flash.now[:error] = t(:create_error, model: t(:manufacturer))
          haml :"manufacturers/new"
        end
      end

      get "/edit/:id" do
        @manufacturer = Manufacturer[params[:id]]
        if @manufacturer
          haml :"manufacturers/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @manufacturer = Manufacturer[params[:id]]
        if @manufacturer
          if @manufacturer.modified! && @manufacturer.update(params[:manufacturer])
            flash[:success] = t(:update_success, model: t(:manufacturer), id: @manufacturer.id)
            redirect(to("manufacturers"))
          else
            flash.now[:error] = t(:update_error, model: t(:manufacturer))
            haml :"manufacturers/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        manufacturer = Manufacturer[params[:id]]
        if manufacturer
          if (manufacturer.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:manufacturer), id: manufacturer.id)
          else
            flash[:error] = t(:delete_error, model: t(:manufacturer))
          end
          redirect to("manufacturers")
        else
          halt 404
        end
      end
    end

    namespace '/contracts' do
      get do
        @contracts = Contract.order(:name).all
        haml :"contracts/index"
      end

      get "/new" do
        @contract = Contract.new
        haml :"contracts/new"
      end

      post "/create" do
        @contract = Contract.new(params[:contract])
        if (@contract.save rescue false)
          flash[:success] = t(:create_success, model: :contract)
          redirect(to("contracts")) 
        else
          flash.now[:error] = t(:create_error, model: :contract)
          haml :"contracts/new"
        end
      end

      get "/edit/:id" do
        @contract = Contract[params[:id]]
        if @contract
          haml :"contracts/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @contract = Contract[params[:id]]
        if @contract
          if @contract.modified! && @contract.update(params[:contract])
            flash[:success] = t(:update_success, model: :contract, id: @contract.id)
            redirect(to("contracts"))
          else
            flash.now[:error] = t(:update_error, model: :contract)
            haml :"contracts/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        contract = Contract[params[:id]]
        if contract
          if (contract.destroy rescue false)
            flash[:success] = t(:delete_success, model: :contract, id: contract.id)
          else
            flash[:error] = t(:delete_error, model: :contract)
          end
          redirect to("contracts")
        else
          halt 404
        end
      end
    end

    namespace '/device_types' do
      get do
        @device_types = get_device_types
        respond_to do |f|
          f.js   { haml :"device_types/index.js", :layout => false }
          f.html { haml :"device_types/index" }
        end
      end

      get "/new" do
        @device_type = DeviceType.new
        haml :"device_types/new"
      end

      post "/create" do
        @device_type = DeviceType.new(params[:device_type])
        if (@device_type.save rescue false)
          flash[:success] = t(:create_success, model: t(:device_type))
          redirect(to("device_types")) 
        else
          flash.now[:error] = t(:create_error, model: t(:device_type))
          haml :"device_types/new"
        end
      end

      get "/edit/:id" do
        @device_type = DeviceType[params[:id]]
        if @device_type
          haml :"device_types/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @device_type = DeviceType[params[:id]]
        if @device_type
          if @device_type.modified! && @device_type.update(params[:device_type])
            flash[:success] = t(:update_success, model: t(:device_type), id: @device_type.id)
            redirect(to("device_types"))
          else
            flash.now[:error] = t(:update_error, model: t(:device_type))
            haml :"device_types/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        device_type = DeviceType[params[:id]]
        if device_type
          if (device_type.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:device_type), id: device_type.id)
          else
            flash[:error] = t(:delete_error, model: t(:device_type))
          end
          redirect to("device_types")
        else
          halt 404
        end
      end
    end

    namespace '/cartridge_types' do
      get do
        @cartridge_types = get_cartridge_types
        respond_to do |f|
          f.js   { haml :"cartridge_types/index.js", :layout => false }
          f.html { haml :"cartridge_types/index" }
        end
      end

      get "/new" do
        @cartridge_type = CartridgeType.new
        haml :"cartridge_types/new"
      end

      post "/create" do
        @cartridge_type = CartridgeType.new(params[:cartridge_type])
        if (@cartridge_type.save rescue false)
          flash[:success] = t(:create_success, model: t(:cartridge_type))
          redirect(to("cartridge_types")) 
        else
          flash.now[:error] =  t(:create_error, model: t(:cartridge_type))
          haml :"cartridge_types/new"
        end
      end

      get "/edit/:id" do
        @cartridge_type = CartridgeType[params[:id]]
        if @cartridge_type
          haml :"cartridge_types/edit"
        else
          halt 404
        end
      end

      put "/update/:id" do
        @cartridge_type = CartridgeType[params[:id]]
        if @cartridge_type
          if @cartridge_type.modified! && @cartridge_type.update(params[:cartridge_type])
            flash[:success] = t(:update_success, model: t(:cartridge_type), id: @cartridge_type.id)
            redirect(to("cartridge_types"))
          else
            flash.now[:error] = t(:update_error, model: t(:cartridge_type))
            haml :"cartridge_types/edit"
          end
        else
          halt 404
        end
      end

      delete "/destroy/:id" do
        cartridge_type = CartridgeType[params[:id]]
        if cartridge_type
          if (cartridge_type.destroy rescue false)
            flash[:success] = t(:delete_success, model: t(:cartridge_type), id: cartridge_type.id)
          else
            flash[:error] = t(:delete_error, model: t(:cartridge_type))
          end
          redirect to("cartridge_types")
        else
          halt 404
        end
      end
    end
    private
    def get_data_for_sidebar
      @type_total = HashWithIndifferentAccess[]
      @types = DeviceType.order(:name)
      @types.each do |key|
        @type_total[key.id] = 0
      end
      device_counts = Device.join(:device_models, device_type_id: :id ).group_and_count(:device_type_id).all
      device_counts.each do |device|
        @type_total[device[:device_type_id]] = device[:count]
      end
    end 

    def get_devices(options = {})
      @view = view_device
      filter = session[:devices_filter].to_s.split(',')
      query = params[:query]
      scope = Device.find_all_grouped(@view)
      scope = scope.where(device_type_id: filter) if filter.present?
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20) unless request.path_info.end_with? ".xls"
      scope.by_code
    end

    def get_cartridges(options = {})
      @view = view_cartridge
      filter = session[:cartridges_filter].to_s.split(',')
      query = params[:query]
      scope = Cartridge.find_all_grouped(@view)
      scope = scope.where(cartridge_type_id: filter) if filter.present?
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20) unless request.path_info.end_with? ".xls"
      @types = CartridgeType.order(:name)
      scope.by_code
    end

    def get_events 
      @view = view_event
      filter = session[@type].to_s.split(',')
      query = params[:query]
      scope = Event.find_all_grouped(@view)
      scope = scope.send(@type, filter) if filter.present?
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)# unless request.path_info.end_with? ".xls"
      scope
    end

    def get_places
      query = params[:query]
      scope = Place.select(:id, :name, :warehouse, :disabled).order(:disabled, :name)
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)
      scope
    end

    def get_manufacturers
      query = params[:query]
      scope = Manufacturer.order(:name)
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)
      scope
    end

    def get_cartridge_models
      query = params[:query]
      scope = CartridgeModel.prepare
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)
      scope
    end

    def get_device_models
      query = params[:query]
      scope = DeviceModel.prepare
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)
      scope
    end

    def get_device_types
      query = params[:query]
      scope = DeviceType.order(:name)
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)
      scope
    end 

    def get_cartridge_types
      query = params[:query]
      scope = CartridgeType.order(:name)
      scope = scope.text_search(query) if query.present?
      scope = scope.extension(:pagination).paginate(current_page, 20)
      scope
    end 

    def page_param
      page = params[:page]&.to_i
      [0, page].max if page
    end

    def current_page
      page = params[:page] || 1
      page.to_i
    end



  end
end

