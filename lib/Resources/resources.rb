module Pomerania::Resources
  class Resource
    def get_property(name)
      ensure_property_table
      if(@property_table[name].is_a?Pomerania::Serialization::LazyLoader)
        return @property_table[name].retrieve
      end
      @property_table[name]
    end
    def set_property(name,value)
      ensure_property_table
      @property_table[name]=value
    end
    def ensure_property_table()
      if(@property_table==nil)
        @property_table={}
      end
    end
    def uri=uri
      @uri=uri
    end
    def uri
      @uri
    end
  end
end