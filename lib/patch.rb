class Patch
  def initialize
    @replaces={}
  end

  def method_missing(meth, *args, &block)
    if meth.to_s.end_with? '='
       @replaces[meth.to_s[0..-2]]=args.first
    else
      super
    end
  end

  def replacements
    @replaces
  end
end