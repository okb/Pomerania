require File.dirname(__FILE__) + '/Pomerania/version'
require File.dirname(__FILE__) + '/Resources/resources'
require File.dirname(__FILE__) + '/schema'
require File.dirname(__FILE__) + '/repository'
require File.dirname(__FILE__) + '/query'
require 'json'
module Pomerania
  class DependencySorter < Hash
    include TSort
    alias tsort_each_node each_key
    def tsort_each_child(node, &block)
      fetch(node).each(&block)
    end
  end
  class Client
    def initialize(uri, headers=nil)
      @uri=uri
      @schema=Schema.new("#{uri}schemas/",headers)
      if(!Client.defined_module?(@schema.namespace))
        generate_module(@schema)
        generate_classes(@schema)
        generate_repos(uri,headers)
      end
    end
    def self.defined_module? name
      begin #jesus
        mod = Required::Module::const_get "Pomerania::Resources::"+name
        return true
      rescue NameError
        return false
      end
    end
    def sort_types_by_dependency(input_types)
      dependency_array=input_types.map do|x|
        if(x.extends==nil)
          [x.name,[]]
        else
          [x.name,[x.extends]]
        end
      end
      DependencySorter[Hash[*dependency_array.flatten(1)]].tsort.map { |x| input_types.select { |y| y.name==x }.first }
    end
    def generate_module(schema)
      Pomerania::Resources.module_eval("module #{@schema.namespace} end")
    end

    def generate_classes(schema)
      types=sort_types_by_dependency(schema.types)
      types.each do |type_definition|
        if(type_definition.extends==nil)
          Pomerania::Resources.module_eval("#{@schema.namespace}::#{type_definition.name}=Class.new Pomerania::Resources::Resource")
        else
          Pomerania::Resources.module_eval("#{@schema.namespace}::#{type_definition.name}=Class.new #{@schema.namespace}::"+type_definition.extends)
        end
        type_definition.properties.each do |prop|
          Pomerania::Resources.module_eval("#{@schema.namespace}::#{type_definition.name}.class_eval('
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
            @@#{function_name}_repository
          end
        ")
        resource_type=@schema.get_type_definition_for_uri(key)
        eval "@@#{function_name}_repository=Repository.new Pomerania::Resources::#{@schema.namespace}::#{resource_type.name}, \"#{uri+resource_type.uri}\", headers,@schema"
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
