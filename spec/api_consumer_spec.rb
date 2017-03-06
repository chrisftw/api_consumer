require './spec/spec_helper'
require './examples/wikipedia.rb'
require './examples/kuakes.rb'

describe APIConsumer do
  describe "cache" do
    it "should have a cache" do
      expect(Wikipedia.cache).not_to eq(nil)
    end
    
    it "should know if cache is enabled via settings" do
      expect(Wikipedia.memcache?).to eq(true)
    end
  end
  
  describe "self-caching" do
    before do
      FakeWeb.register_uri(
        :get, "http://en.wikipedia.org/w/api.php?format=json&action=query&titles=Soylent%20Green&prop=revisions&rvprop=content",
        :body => File.read("spec/mock/api_responses/soylent_green.json")
      )
      FakeWeb.register_uri(
        :get, "http://www.kuakes.com/json/",
        :body => File.read("spec/mock/api_responses/kuakes.json")
      )
    end
    
    it "should accept a block to parse the data" do
      last10 = Kuakes.do_request("/json/", Kuakes.connection(:kuakes), {:key => "last-10-quakes", :reload => true}) do |data|
        data[1..10]
      end
      expect(last10.length).to eq(10)
      expect(last10[1]["title"].include?("Corralitos, California")).to eq(true)
    end
    
    it "should read from cache, and return blocked object" do
      last10 = Kuakes.do_request("/json/", Kuakes.connection(:kuakes), {:key => "last-10-quakes", :reload => true}) do |data|
        data[1..10]
      end
      expect(last10.length).to eq(10)
      expect(last10[1]["title"].include?("Corralitos, California")).to eq(true)
      expect{ Kuakes.do_request("/json/", Kuakes.connection(:kuakes), {:key => "last-10-quakes"}) do |data|
        throw Exception, "Did not read from cache."
        data[1..10]
      end }.not_to raise_error
    end
    
    it "should return all parsed json data if no block given" do
      last50 = Kuakes.do_request("/json/", Kuakes.connection(:kuakes), {:key => "last-50-quakes", :reload => true})
      expect(last50.length).to eq(51)
      expect(last50[2]["title"].include?("Corralitos, California")).to eq(true)
      expect{ Kuakes.do_request("/json/", Kuakes.connection(:kuakes), {:key => "last-50-quakes"}) do |data|
        throw Exception, "Did not read from cache."
      end }.not_to raise_error
    end
    
    it "should return string data if not json, and no block" do
      pending "more examples need to be found/made to test this"
      fail
    end
    
    it "should return whatever block creates if not json, and block was given" do
      pending "more examples need to be found/made to test this"
      fail
    end
  end
  
  describe "settings" do
    it "should know it's settings" do
      expect(Wikipedia.settings[:url]).to eq("http://en.wikipedia.org")
      expect(Wikipedia.settings[:use_memcache]).to eq(true)
    end
    
    it "should allow custom config settings" do
      expect(Wikipedia.settings[:random_setting]).to eq("custom config settings here")
    end
    
    it "should not know settings never set" do
      expect(Wikipedia.settings[:fake_key]).to eq(nil)
    end
  end
  
  describe "parsing" do
    it "should parse json" do
      pending "need to write this test still"
      fail
    end
    
    it "should parse rss" do
      pending "need to write this test still"
      fail
    end
  end
  
  describe "api" do
    before do
      FakeWeb.register_uri(
        :get, "http://en.wikipedia.org/w/api.php?format=json&action=query&titles=Soylent%20Green&prop=revisions&rvprop=content",
        :body => File.read("spec/mock/api_responses/soylent_green.json")
      )
      FakeWeb.register_uri(
        :get, "http://www.kuakes.com/json/",
        :body => File.read("spec/mock/api_responses/kuakes.json")
      )
    end
    
    it "should call api" do
      result = Wikipedia.fetch("Soylent Green")
      expect(result["query"]["pages"]["45481"]["title"]).to eq("Soylent Green")
      expect(result["query"]["pages"]["45481"]["revisions"][0]["*"].include?("[[Richard Fleischer]]")).to eq(true)
    end
    
    it "should call other APIs setup with api_consumer" do
      quakes = Kuakes.all(true)
      expect(quakes.length).to eq(50)
      expect(quakes[1]["title"].include?("Corralitos, California")).to eq(true)
    end
  end
  
  describe "logger" do
    it "should create a logger automagically" do
      expect(Wikipedia.log).not_to eq(nil)
    end
    
    it "should write to the logger" do
      expect{Wikipedia.log.warn("hello logger")}.not_to raise_error
    end
    
    it "should read custom log files from settings" do
      Kuakes.log.error("sample error")
    end
  end
end
