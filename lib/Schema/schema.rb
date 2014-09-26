#coding: utf-8
require 'net/http'
require 'json'
require File.dirname(__FILE__) + '/type_definition'
module Pomerania::Schema
  class Schema
    attr_reader :types,:namespace

    def initialize(uri,namespace=nil, headers=nil)
      if(namespace==nil)
        @namespace=URI.parse(uri).host.gsub(/[^a-z ]/i, '').capitalize
      else
        @namespace=namespace
      end

      parse(retrieve(headers, uri))
    end

    def get_type_definition_for(klass)
      resource_type=@types.select do|x|
        "Pomerania::Resources::"+@namespace+"::"+x.name==klass.to_s
      end
      resource_type[0]
    end
    def is_pomona_type?(klass)
      @types.select{|x|x.name==klass.to_s}.length==1
    end
    def get_type_definition_for_uri(uri)
      resource_type=@types.select do|x|
        x.uri==uri&&x.extends==nil
      end
      resource_type[0]
    end

    def retrieve(headers, uri)
      parsed_uri=URI.parse(uri)
      req = Net::HTTP::Get.new parsed_uri.request_uri
      req.initialize_http_header(headers)
      res = Net::HTTP.start(parsed_uri.hostname, parsed_uri.port) { |http|
        http.request(req)
      }
      res.body
    end
    def parse(json_string)
      parsed_hash=JSON.parse(json_string)
      @version=parsed_hash["version"]
      @types=parse_types parsed_hash["types"]
    end
    def parse_types(type_array)
      parsed_types=[]
      type_array.map do |type_hash|
        parse_type type_hash
      end
    end
    def parse_type(type_hash)
      TypeDefinition.new(type_hash["name"],type_hash["uri"],type_hash["extends"],parse_properties(type_hash["properties"]))
    end
    def parse_properties(property_hash)
      property_hash.map do |k,val|
          if(val["type"]=="array")
            PropertyDefinition.new k ,val["type"], val["items"][0]["type"]
          else
            PropertyDefinition.new k ,val["type"] ,nil
          end
      end
    end
  end
end
