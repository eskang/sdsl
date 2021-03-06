# mod.rb
# TODO: Data
#
require 'rubygems'
require 'docile'
require 'myutils.rb'
require 'datatype.rb'

Mod = Struct.new(:name, :exports, :invokes, :assumptions, 
                 :stores, :creates,
                 :extends, :isAbstract, :isUniq)
Op = Struct.new(:name, :constraints, :parent, :child)

class Mod

  def findExport n
    (exports.select { |e| e.name == n })[0]
  end

  def findInvoke n    
    (invokes.select { |i| i.name == n})[0]
  end

  def deepclone 
    Mod.new(self.name, self.exports.clone, self.invokes.clone,
            self.assumptions.clone, self.stores.clone, 
            self.creates.clone, self.extends.clone, 
            self.isAbstract, self.isUniq)
  end

  def to_alloy(ctx)
    # (s1, s2) in decls => sig s1 extends s2
    sigfacts = []
    facts = []
    fields = []
    alloyChunk = ""

    modn = name.to_s    
    # module declaration
    fields = stores

    ctx[:nesting] = 1
    exports.each do |o|
      n = o.name
      ctx[:op] = n
      # receiver constraint
      # export constraint
      o.constraints[:when].each do |c|
        f = "all o : this.receives[" + n.to_s + "] | " + c.to_alloy(ctx)
        sigfacts << f        
      end
    end

    # newInvokes = []
    # invokes.each do |o|
    #   n = o.name
    #   # replace the invoked op with the set of all replaced ops
    #   if not (ctx[n].count == 1 and ctx[n].include? n.to_s)
    #     ctx[n].each do |newOpName|           
    #       newInvokes << Op.new(newOpName.to_sym, 
    #                            :when => o.constraints[:when])
    #     end
    #   else
    #     newInvokes << o
    #   end
    # end
    # self.invokes = newInvokes.dup
 
    invokes.each do |o|
      n = o.name.to_s
      ctx[:op] = n
      o.constraints[:when].each do |c|
        f = "all o : this.sends[" + n + "] | " + c.to_alloy(ctx)
        sigfacts << f
      end
    end

    sigfacts += assumptions.map {|m| m.to_alloy(ctx)}

    # write Alloy expressions
    # declarations 
    alloyChunk += wrap("-- module " + modn)
    if isUniq then alloyChunk += "one " end
    alloyChunk += wrap("sig " + modn + " extends Module {")
    # fields      
    fields.each do |f|
      alloyChunk += wrap(f.to_alloy(ctx) + ",", 1)
    end
    alloyChunk += "}"
    # signature facts
    if not sigfacts.empty? 
      alloyChunk += wrap("{")
      sigfacts.each do |f|
        alloyChunk += wrap(f, 1)
      end
      alloyChunk += wrap("}")
    end

    # facts
    alloyChunk += writeFacts(name.to_s + "Facts", facts)
  end
end

class ModuleBuilder
  def initialize 
    @exports = []
    @invokes = []
    @assumptions = []
    @stores = []
    @creates = []
    @extends = []
    @isAbstract = false
    @isUniq = true
  end

  def exports(op, constraints = {})   
    if constraints.empty?
      @exports << Op.new(op, {:when => [], :args => []})
    else
      if not constraints.has_key? :args
        constraints[:args] = []
      end
      if not constraints.has_key? :when
        constraints[:when] = []
      end
      @exports << Op.new(op, constraints)
    end
  end

  def invokes(op, constraints = {})
    if constraints.empty?
      @invokes << Op.new(op, :when => []) 
    else 
      if not constraints.has_key? :when
        constraints[:when] = []
      end
      @invokes << Op.new(op, constraints)
    end
  end

  def assumes(*constr)
    @assumptions += constr   
  end

  def stores (n, *types)
    if n.is_a? Rel
      obj = n
    elsif types.count == 1
      obj = Item.new(n, types[0])
    elsif types.count == 2
      obj = Map.new(n, types[0], types[1])
    else 
      raise "Invalid stores declaration"
    end

    @stores << obj
  end

  def creates(*data)    
    @creates += data
  end

  def extends parent
    @extends << parent
  end
  
  def setUniq b
    @isUniq = b
  end

  def build name
    Mod.new(name, @exports, @invokes, @assumptions, @stores, 
            @creates, @extends, @isAbstract, @isUniq)
  end
end

def mod(name, &block)
  Docile.dsl_eval(ModuleBuilder.new, &block).build name
end


