
class LazyLoader
  def initialize(property_definition,json_definition,headers,schema)
    @property_definition=property_definition
    @json_definition=json_definition
    @headers=headers
    @schema=schema
    @value=nil
  end
  def retrieve
    if(@value==nil)
      @value=load()
    end
    @value
  end
  def load
    if @property_definition.type_name=="array"
      repository=Repository.new("Pomerania::Resources::"+@schema.namespace+"::"+@property_definition.item_type,@json_definition["_ref"], @headers,@schema)
      repository.list {|x|}
    else
      repository=Repository.new("Pomerania::Resources::"+@schema.namespace+"::"+@property_definition.type_name,LazyLoader::repo_url_from_item_url(@json_definition["_ref"]), @headers,@schema)
      repository.get LazyLoader::item_id_from_item_url(@json_definition["_ref"])
    end
  end
  def self.repo_url_from_item_url(url)
     url.split('/')[0..-2].join('/')
  end
  def self.item_id_from_item_url(url)
     url.split('/').last
  end
end