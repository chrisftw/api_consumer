require 'spec_helper'
require './examples/wikipedia.rb'

describe APIConsumer do
  describe "cache" do
    it "should have a cache" do
      expect(Wikipedia.cache).not_to eq(nil)
    end
    
    it "should know if cache is enabled via settings" do
      expect(Wikipedia.memcache?).to eq(true)
    end
  end
  
  describe "settings" do
    it "should know it's settings" do
      expect(Wikipedia.settings[:url]).to eq("http://en.wikipedia.org")
      expect(Wikipedia.settings[:use_memcache]).to eq(true)
    end
  end
  
  describe "api" do
    before do
      FakeWeb.register_uri(
        :get, "http://en.wikipedia.org/w/api.php?format=json&action=query&titles=Soylent%20Green&prop=revisions&rvprop=content",
        :body => File.read("spec/mock/api_responses/soylent_green.json")
      )
    end
    
    it "should call api" do
      result = Wikipedia.fetch("Soylent Green")
      expect(result["query"]["pages"]["45481"]["title"]).to eq("Soylent Green")
      expect(result["query"]["pages"]["45481"]["revisions"][0]["*"].include?("[[Richard Fleischer]]")).to eq(true)
    end
  end
  
  describe "logger" do
    it "should create a logger automagically" do
      expect(Wikipedia.log).not_to eq(nil)
    end
    
    it "should write to the logger" do
      expect{Wikipedia.log.warn("hello logger")}.not_to raise_error
    end
  end
end
