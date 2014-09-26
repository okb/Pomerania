require File.dirname(__FILE__) + '/lazy_loader'
class Repository
  def initialize(class_name,uri,headers,schema)
    @class_name=class_name
    @uri=uri
    @headers=headers
    @schema=schema
  end
  def get(id)
     json=LoadFromUri(@headers,@uri+"\/"+id)
     get_resource(@class_name,json)
  end
  def list(&query)                                              #day 1 and this is allready in need of refactoring...
    query_string=yield (Query.new)
    json=LoadFromUri(@headers,@uri+query_string.to_s)

    json["items"].map do |json_item|
      get_resource @class_name, json_item
    end
  end
  def LoadFromUri(headers, uri)
    puts "Making call to "+uri
    parsed_uri=URI.parse(URI::encode(uri))
    req = Net::HTTP::Get.new parsed_uri.request_uri
    req.initialize_http_header(headers)
    res = Net::HTTP.start(parsed_uri.hostname, parsed_uri.port) { |http|
      http.request(req)
    }
    JSON.parse(res.body)
  end

  #from here on is serialization TODO: move out!
  def get_resource(class_name,json)
    if(json["_type"]!=nil)
      class_name="Pomerania::Resources::"+@schema.namespace+"::"+json["_type"]
    end
    item=eval("#{class_name}.new")
    set_property_values(item,class_name,json)
    item
  end

  def set_property_values(item,class_name,json)    #build item. Not very nice but whatevah
    type_def=@schema.get_type_definition_for(class_name)
    type_def.properties.each do |prop|
      eval "item.#{Pomerania::Client::function_name_create(prop.name)}=get_property_value(prop,json[\"#{prop.name}\"])"
    end
    if(type_def.extends!=nil)
      set_property_values(item,"Pomerania::Resources::"+@schema.namespace+"::"+type_def.extends,json)
    end
  end

  def is_lazy?(value)
    if(value.is_a?Hash)
      return value["_ref"]!=nil
    end
    false
  end
  def get_property_value(property_definition,value)
    if(is_lazy?(value))
      return LazyLoader.new(property_definition,value,@headers,@schema)
    end
    if(value==nil)
      return nil
    end
    case property_definition.type_name
      when "string"
        value.to_s
      when "integer"
        value.to_i
      when "array"
        get_array(property_definition,value)
      else
        if(@schema.is_pomona_type?(property_definition.type_name))
          get_resource("Pomerania::Resources::"+@schema.namespace+"::"+property_definition.type_name,value)
        else
          value.to_s
        end
    end
  end
  def get_array(property_definition,value)
     value.map do |x|
       if(x==nil)
         return nil
       end
       case property_definition.item_type
         when "string"
           x.to_s
         when "integer"
           x.to_i
         when "array"
           get_array(property_definition,x)
         else
           if(@schema.is_pomona_type?(property_definition.item_type))
             get_resource("Pomerania::Resources::"+@schema.namespace+"::"+property_definition.item_type,x)
           else
             x.to_s
           end
       end
     end
  end
end