class TypeDefinition
  attr_reader :name,:uri,:properties

  def initialize(name,uri,properties)
    @name=name
    @uri=uri
    @properties=properties
  end
end
class PropertyDefinition
  attr_reader :name,:type_name,:item_type

  def initialize(name,type_name,item_type)
    @name=name
    @type_name=type_name
    @item_type=item_type
  end
end