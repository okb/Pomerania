require File.dirname(__FILE__) + '/lazy_loader'
require File.dirname(__FILE__) + '/patch'
require File.dirname(__FILE__) + '/query'
require File.dirname(__FILE__) + '/Serialization/serializer'
class Repository
  def initialize(class_name,uri,headers,schema)
    @class_name=class_name
    @uri=uri
    @headers=headers
    @serializer=Pomerania::Serialization::Serializer.new schema
  end
  def get(id)
     json=LoadFromUri(@headers,@uri+"\/"+id)
     @serializer.get_resource(@class_name,json)
  end
  def list(&query)                                              #day 1 and this is allready in need of refactoring...
    query_generator=Query.new
    yield (query_generator)
    json=load_from_uri(@headers,@uri+query_generator.to_s)

    json["items"].map do |json_item|
      @serializer.get_resource @class_name, json_item
    end
  end
  def post(entity)
    json= JSON.generate @serializer.create_post_hash(entity)
    @serializer.get_resource(@class_name,post_to_uri(@headers,@uri,json))
  end
  def patch(item,&statements)
    patch=Patch.new()
    yield (patch)
    json=JSON.generate @serializer.create_patch_hash(patch)
    @serializer.get_resource(@class_name,patch_to_uri(@headers,item.uri,json))
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

end