# require 'api_consumer' if using gem
require './lib/api_consumer' # this is just for use in tests here inside the gem

class Wikipedia < APIConsumer
  require 'open-uri'
  # NOTES
  # We automatically get cache method that we can use called 'cache'
  
  # http://en.wikipedia.org/w/api.php?format=json&action=query&titles=Soylent%20Green&prop=revisions&rvprop=content
  def self.fetch(page_name, reload = false)
    return cache.read(page_name) if memcache? && !reload && cache.read(page_name)
    encoded_page_name = URI::encode(page_name) # encoding for Wikipedia's API, not for APIConsumer.
    obj_hash = do_request("/w/api.php?format=json&action=query&titles=#{encoded_page_name}&prop=revisions&rvprop=content", connection(:some_flag_here))
    cache.write(page_name, obj_hash) if memcache?
    return obj_hash
  end
  
end
