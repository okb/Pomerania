
module Pomerania::Schema
  class TypeDefinition
    attr_reader :name,:uri,:properties, :extends

    def initialize(name,uri,extends,properties)
      @name=name
      @uri=uri
      @extends=extends
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
end