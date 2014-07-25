require File.dirname(__FILE__) + '/Pomerania/version'
require File.dirname(__FILE__) + '/Resources/resources'
require File.dirname(__FILE__) + '/schema'
require File.dirname(__FILE__) + '/repository'
require 'json'

module Pomerania
  class Client
    def initialize(uri, headers=nil)
      @uri=uri
      @schema=Schema.new("#{uri}schemas/",headers)
      generate_classes(@schema)
      generate_repos(uri,headers)
    end
    def generate_classes(schema)
      schema.types.each do |type_definition|
        eval("Pomerania::Resources::#{type_definition.name}=Class.new Pomerania::Resources::Resource")

        eval("Pomerania::Resources::#{type_definition.name}.class_eval('
          def initialize()
            puts  \":#{type_definition.name} Created\"
          end
          ')")
        type_definition.properties.each do |prop|
          eval("Pomerania::Resources::#{type_definition.name}.class_eval('
          def #{Client::function_name_create(prop.name)}
            get_property(\"#{prop.name}\")
          end
          def #{Client::function_name_create(prop.name)}=(value)
            set_property(\"#{prop.name}\",value)
          end
          ')")
        end
      end
    end
    def self.function_name_create(name)
      name.gsub('-','_')
    end
    def generate_repos(uri, headers=nil)
      LoadFromUri(headers, uri).each_pair do |key,value|
        function_name=Client::function_name_create(key)
        Client.class_eval("
          def #{function_name}
            @#{function_name}_repository
          end
        ")
        resource_type=@schema.get_type_definition_for_uri(key)
        eval "@#{function_name}_repository=Repository.new Pomerania::Resources::#{resource_type.name}, \"#{uri+resource_type.uri}\", headers,@schema"
      end
    end

    def LoadFromUri(headers, uri)
      parsed_uri=URI.parse(uri)
      req = Net::HTTP::Get.new parsed_uri.request_uri
      req.initialize_http_header(headers)
      res = Net::HTTP.start(parsed_uri.hostname, parsed_uri.port) { |http|
        http.request(req)
      }
      JSON.parse(res.body)
    end
  end
end
