module Library
  module Helpers
    module ApplicationHelpers
      def matrix_action 
        return [
          [false, true, false, true, false, true, true ],
          [false, false, true, false, false, true, false ],
          [true, true, false, true, false, true, true ],
          [false, false, false, false, true, false, false ],
          [true, false, false, false, false, false, false]
        ]
      end

      def protected!
        return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
      end
    
      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [settings.user, settings.password]
      end


      # This code is licensed under the MIT License
      # author https://github.com/padrino/padrino-framework
      NEWLINE = "\n".html_safe.freeze
      def content_tag(name, content = nil, options = nil, &block)
        if block_given?
          options = content if content.is_a?(Hash)
          content = capture_html(&block)
        end
        options    = parse_data_options(name, options)
        attributes = tag_attributes(options)
        output = ActiveSupport::SafeBuffer.new
        output.safe_concat "<#{name}#{attributes}>"
        if content.respond_to?(:each) && !content.is_a?(String)
          content.each{ |item| output.concat item; output.safe_concat NEWLINE }
        else
          output.concat content.to_s
        end
        output.safe_concat "</#{name}>"
        capture_haml { output }
      end

      DATA_ATTRIBUTES = [
        :method,
        :remote,
        :confirm
      ]

      def parse_data_options(tag, options)
        return unless options
        parsed_options = options.dup
        options.each do |key, value|
          next if !DATA_ATTRIBUTES.include?(key) || (tag.to_s == 'form' && key == :method)
          parsed_options["data-#{key}"] = parsed_options.delete(key)
          parsed_options[:rel] = 'nofollow' if key == :method
        end
        parsed_options
      end

      def tag_attributes(options)
        return '' unless options
        options.inject('') do |all, (key,value)|
          next all unless value
          all << ' ' if all.empty?
          all << if value.is_a?(Hash)
            nested_values(key, value)
          else
            %(#{key}="#{value}" )
          end
        end.chomp!(' ')
      end

      def flash_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        bootstrap = options.delete(:bootstrap) if options[:bootstrap]
        args.inject([]) do |html,kind|
          next html unless flash[kind]
          flash_text = [] << flash[kind]
          flash_text << content_tag(:button, '&times;'.html_safe, {:type => :button, :class => :close, :'data-dismiss' => :alert}) if bootstrap
          html << content_tag(:div, flash_text, { :class => kind }.update(options))
        end
      end

      def tag(name, options = nil, open = false)
        attributes = tag_attributes(options)
        "<#{name}#{attributes}#{open ? '>' : ' />'}"
      end
      def select_tag(name, options={})
        options = { :name => name }.merge(options)
        options[:name] = "#{options[:name]}[]" if options[:multiple]
        content_tag(:select, extract_option_tags!(options), options)
      end

      def extract_option_tags!(options)
        state = extract_option_state!(options)
        option_tags = if options[:grouped_options]
          grouped_options_for_select(options.delete(:grouped_options), state)
        else
          options_for_select(extract_option_items!(options), state)
        end
        if prompt = options.delete(:include_blank)
          option_tags.unshift(blank_option(prompt))
        end
        option_tags
      end

      def blank_option(prompt)
        case prompt
        when nil, false
          nil
        when String
          content_tag(:option, prompt,       :value => '')
        when Array
          content_tag(:option, prompt.first, :value => prompt.last)
        else
          content_tag(:option, '',           :value => '')
        end
      end

      def option_is_selected?(value, caption, selected_values)
        Array(selected_values).any? do |selected|
          value ?
            value.to_s == selected.to_s :
            caption.to_s == selected.to_s
        end
      end

      def options_for_select(option_items, state = {})
        return [] if option_items.count == 0
        option_items.map do |caption, value, attributes|
          html_attributes = { :value => value || caption }.merge(attributes||{})
          html_attributes[:selected] ||= option_is_selected?(html_attributes[:value], caption, state[:selected])
          html_attributes[:disabled] ||= option_is_selected?(html_attributes[:value], caption, state[:disabled])
          content_tag(:option, caption, html_attributes)
        end
      end

      def extract_option_state!(options)
        {
          :selected => Array(options.delete(:value))|Array(options.delete(:selected))|Array(options.delete(:selected_options)),
          :disabled => Array(options.delete(:disabled_options))
        }
      end

      def extract_option_items!(options)
        if options[:collection]
          fields = options.delete(:fields)
          collection = options.delete(:collection)
          collection.map{ |item| [ item.send(fields.first), item.send(fields.last) ] }
        else
          options.delete(:options) || []
        end
      end

      def simple_format(text, options={})
        t = options.delete(:tag) || :p
        start_tag = tag(t, options, true)
        text = escape_html(text.to_s.dup) unless text.html_safe?
        text.gsub!(/\r\n?/, "\n")                      # \r\n and \r -> \n
        text.gsub!(/\n\n+/, "</#{t}>\n\n#{start_tag}") # 2+ newline  -> paragraph
        text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />')   # 1 newline   -> br
        text.insert 0, start_tag
        text << "</#{t}>"
        text.html_safe
      end


      def truncate(text, options={})
        options = { :length => 30, :omission => "..." }.update(options)
        if text
          len = options[:length] - options[:omission].length
          chars = text
          (chars.length > options[:length] ? chars[0...len] + options[:omission] : text).to_s
        end
      end

      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false, options = {})
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        distance_in_minutes = (((to_time.to_i - from_time.to_i).abs)/60).round
        distance_in_seconds = ((to_time.to_i - from_time.to_i).abs).round

        phrase, locals =
          case distance_in_minutes
            when 0..1
              if include_seconds
                case distance_in_seconds
                  when 0..4   then [:less_than_x_seconds, :count => 5 ]
                  when 5..9   then [:less_than_x_seconds, :count => 10]
                  when 10..19 then [:less_than_x_seconds, :count => 20]
                  when 20..39 then [:half_a_minute                    ]
                  when 40..59 then [:less_than_x_minutes, :count => 1 ]
                  else             [:x_minutes,           :count => 1 ]
                end
              else
                distance_in_minutes == 0 ?
                  [:less_than_x_minutes, :count => 1] :
                  [:x_minutes, :count => distance_in_minutes]
              end
            when 2..44           then [:x_minutes,      :count => distance_in_minutes                       ]
            when 45..89          then [:about_x_hours,  :count => 1                                         ]
            when 90..1439        then [:about_x_hours,  :count => (distance_in_minutes.to_f / 60.0).round   ]
            when 1440..2529      then [:x_days,         :count => 1                                         ]
            when 2530..43199     then [:x_days,         :count => (distance_in_minutes.to_f / 1440.0).round ]
            when 43200..86399    then [:about_x_months, :count => 1                                         ]
            when 86400..525599   then [:x_months,       :count => (distance_in_minutes.to_f / 43200.0).round]
            else
              distance_in_years           = distance_in_minutes / 525600
              minute_offset_for_leap_year = (distance_in_years / 4) * 1440
              remainder                   = ((distance_in_minutes - minute_offset_for_leap_year) % 525600)
              if remainder < 131400
                [:about_x_years,  :count => distance_in_years]
              elsif remainder < 394200
                [:over_x_years,   :count => distance_in_years]
              else
                [:almost_x_years, :count => distance_in_years + 1]
              end
          end
        I18n.translate phrase, locals.merge(:locale => options[:locale], :scope => :'datetime.distance_in_words')
      end

      def time_ago_in_words(from_time, include_seconds = false)
        distance_of_time_in_words(from_time, Time.now, include_seconds)
      end

      def js_escape_html(html_content)
        return '' unless html_content
        javascript_mapping = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
        escaped_content = html_content.gsub(/(\\|<\/|\r\n|[\n\r"'])/){ |m| javascript_mapping[m] }
        escaped_content = escaped_content.html_safe if html_content.html_safe?
        escaped_content
      end
      alias :escape_javascript :js_escape_html

      def model_attribute_translate(model, attribute)
        t("models.#{model}.attributes.#{attribute}", :default => attribute.to_s.humanize)
      end
      alias :mat :model_attribute_translate

      def model_translate(model)
        t("models.#{model}.name", :default => model.to_s.humanize)
      end
      alias :mt :model_translate

      def admin_translate(word, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:default] ||= word.to_s.humanize
        t("admin.#{word}", options)
      end
      alias :pat :admin_translate
    end
  end
end