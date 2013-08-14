# data.rb
#

Data = Struct.new(:name)

class RefinedData < Mod
  attr_accessor :refines
  
  def initialize(n, r)
    super(n)
    @refines = r
  end
end
