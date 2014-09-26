require File.dirname(__FILE__) + '/lazy_loader'
require File.dirname(__FILE__) + '/patch'
require File.dirname(__FILE__) + '/query'
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
    query_generator=Query.new
    yield (query_generator)
    json=load_from_uri(@headers,@uri+query_generator.to_s)

    json["items"].map do |json_item|
      get_resource @class_name, json_item
    end
  end
  def post(entity)
    json= JSON.generate create_post_hash(entity)
    get_resource(@class_name,post_to_uri(@headers,@uri,json))
  end
  def patch(item,&statements)
    patch=Patch.new()
    yield (patch)
    json=JSON.generate create_patch_hash(patch)
    get_resource(@class_name,patch_to_uri(@headers,item.uri,json))
  end
  def load_from_uri(headers, uri)
    puts "Getting from "+uri
    parsed_uri=URI.parse(URI::encode(uri))
    req = Net::HTTP::Get.new parsed_uri.request_uri
    req.initialize_http_header(headers)
    res = Net::HTTP.start(parsed_uri.hostname, parsed_uri.port) { |http|
      http.request(req)
    }
    JSON.parse(res.body)
  end
  def post_to_uri(headers, uri,payload)
    puts "Posting to "+uri
    puts payload
    parsed_uri=URI.parse(URI::encode(uri))
    req = Net::HTTP::Post.new parsed_uri.request_uri
    req.initialize_http_header(headers)
    req.body=payload
    res = Net::HTTP.start(parsed_uri.hostname, parsed_uri.port) { |http|
      http.request(req)
    }
    JSON.parse(res.body)
  end

  def patch_to_uri(headers, uri,payload)
    puts "Patch to "+uri
    puts payload
    parsed_uri=URI.parse(URI::encode(uri))
    req = Net::HTTP::Patch.new parsed_uri.request_uri
    req.initialize_http_header(headers)
    req.body=payload
    res = Net::HTTP.start(parsed_uri.hostname, parsed_uri.port) { |http|
      http.request(req)
    }
    JSON.parse(res.body)
  end


  #from here on is serialization TODO: move out!
  def create_post_hash(entity)
     if(entity.is_a?(Pomerania::Resources::Resource))
       if(entity.uri!=nil)
         return {"_ref"=>entity.uri}
       end

       if(entity.is_a?(LazyLoader))
         return {"_ref"=>entity.ref}
       end

       properties={}
       @schema.get_type_definition_for(entity.class).properties.each do |x|
         if(entity.get_property(x.name)!=nil)
           properties[x.name]=create_post_hash(entity.get_property x.name)
         end
       end

       return properties
     end
     return entity
  end
  def create_patch_hash(patch)
    hash={}
    patch.replacements.each do |key, value|
      hash[key]=create_post_hash value
    end
    hash
  end
  def get_resource(class_name,json)
    if(json["_type"]!=nil)
      class_name="Pomerania::Resources::"+@schema.namespace+"::"+json["_type"]
    end
    item=eval("#{class_name}.new")
    if(json["_uri"]!=nil)
      item.uri= json["_uri"]
    end
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