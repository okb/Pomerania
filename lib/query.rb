class Query
  def initialize
    @filters=[]
    @expands=[]
  end
  def filter new_filter
    @filters<<new_filter
  end
  def expand new_expand
    @expands<<new_expand
  end

  def to_s
    query_string=""
    if(@filters.count>0)
      query_string=query_string+"?$filter=\""+@filters.map{|x|x.to_s}.join(' and ')+"\""
    end
    if(@expands.count>0)
      if(query_string=="")
        query_string="?"
      else
        query_string=query_string+"&"
      end
      query_string=query_string+"$expand="+@expands.map{|x|x.to_s}.join('&$expand=')
    end
    query_string
  end
end