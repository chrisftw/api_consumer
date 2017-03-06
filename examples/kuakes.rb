# require 'api_consumer' if using gem
require './lib/api_consumer' # this is just for use in tests here inside the gem

class Kuakes < APIConsumer
  # NOTES
  # We automatically get cache method that we can use called 'cache'
  
  # http://www.kuakes.com/json/
  def self.all(reload = false)
    return cache.read("kuakes-quakes") if memcache? && !reload && cache.read("kuakes-quakes")
    quakes_array = do_request("/json/", connection(:kuakes))
    status = quakes_array.shift
    log.info("LOOKUP STATUS: #{status.inspect}")
    cache.write("kuakes-quakes", quakes_array) if memcache?
    return quakes_array
  end
  
end
