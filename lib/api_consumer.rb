class APIConsumer
  require 'yaml'
  require "net/https"
  require "uri"
  require "json"
  require 'uber_cache'

  class << self
    @settings = {}
    def inherited(subclass)
      configs = YAML.load_file("config/#{snake_case(subclass)}.yml")
      configs[snake_case(subclass)].each{ |k,v| subclass.set(k.to_sym, v) }
      super
    end
    
    def memcache?
      settings[:use_memcache]
    end
    
    def memcache_hosts
      settings[:memcache_hosts]
    end

    def set(key, val)
      settings[key] = val
    end

    def settings
      @settings ||= {}
    end
    
    DEFAULT_REQUEST_OPTS = {:method => :get, :headers => { "Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "EME-WEB-STORE-#{ENV['RACK_ENV']|| 'dev'}" }}
    def do_request(path, conn, opts = {})
      opts[:headers] = DEFAULT_REQUEST_OPTS[:headers].merge(opts[:headers] || {})
      opts[:method] = opts[:method] || DEFAULT_REQUEST_OPTS[:method]

      req = if( opts[:method] == :get)
        Net::HTTP::Get.new(path)
      elsif( opts[:method] == :post)
        Net::HTTP::Post.new(path)
      else
        puts "BUG - method=>(#{opts[:method]})"
      end
      opts[:headers].each { |k,v| req[k] = v }
      req.basic_auth settings[:api_user], settings[:api_password] if settings[:api_user] && settings[:api_password]
      req["connection"] = 'keep-alive'
      req.body = opts[:body] if opts[:body]
      #puts( "REQUEST!!! #{opts[:headers]} #{path};\n#{@uri.host}:::#{@uri.port}")
      #puts("BODY: #{req.body}")

      response = nil
      begin
        response = conn.request(req)
        if( settings[:type] == "json")
          results = JSON.parse(response.body)
          if ![200, 201].include?(response.code.to_i)
            results = error_code(response.code, opts[:errors])
          end
          return results
        end
      rescue Exception => exception
        puts exception.message
        puts exception.backtrace
        puts "================="
        # Airbrake.notify(exception)
        if( settings[:type] == "json")
          return error_code(response.code, opts[:errors])
        end
      end
      return response.body
    end
    
    def connection(connection_flag = :normal)
      @connections ||= {}
      return @connections[connection_flag] if @connections[connection_flag]
      @connections[connection_flag] = create_connection
    end
    
    def create_connection(debug = false)
      if @uri.nil? || @uri.port.nil?
        #puts "TRYING TO CONNECT: #{settings[:url]}"
        @uri = URI.parse("#{settings[:url]}/")
      end
      http = Net::HTTP.new(@uri.host, @uri.port)
      if settings[:ssl] == true
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.set_debug_output $stderr if debug
      http.open_timeout = 7
      http.read_timeout = 15
      http
    end

    def cache
      @cache ||= UberCache.new(settings[:cache_prefix], settings[:memcache_hosts])
    end

    private
    def snake_case(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end
    
    def error_code(code, errors = nil)
      return {:error => true, :message => errors[code.to_s]} if errors && errors[code.to_s]
      return {:error => true, :message => "API error: #{code}" }
    end
  end
end
