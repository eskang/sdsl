# mod.rb
# TODO: Data
#
require 'rubygems'
require 'docile'
require 'myutils.rb'

Mod = Struct.new(:name, :exports, :invokes, :constraints, 
                 :stores, :creates,
                 :extends, :isAbstract)
Op = Struct.new(:name, :constraints, :parent, :child)

class Mod

  def to_alloy(ctx)
    # (s1, s2) in decls => sig s1 extends s2
    sigfacts = []
    facts = []
    fields = []
    alloyChunk = ""

    modn = name.to_s    
    # module declaration
    fields = stores

    exports.each do |o|
      n = o.name.to_s
      ctx[:op] = n
      c = o.constraints[:when].to_alloy(ctx)
      # receiver constraint
      # export constraint
      if not c == UNIT 
        f = "all o : this.receives[(" + n + ")] | " + c
        sigfacts << f
      end
    end

    newInvokes = []
    invokes.each do |o|
      n = o.name
      # replace the invoked op with the set of all replaced ops
      if not (ctx[n].count == 1 and ctx[n].include? n.to_s)
        ctx[n].each do |newOpName|           
          newInvokes << Op.new(newOpName.to_sym, 
                               :when => o.constraints[:when])
        end
      else
        newInvokes << o
      end
    end
    self.invokes = newInvokes.dup
    
    invokes.each do |o|
      n = o.name.to_s
      ctx[:op] = n
      c1 = o.constraints[:when].to_alloy(ctx)
      if not c1 == UNIT
        f1 = "all o : this.sends[(" + n + ")] | " + c1
        sigfacts << f1
      end
    end

    # write Alloy expressions
    # declarations 
    alloyChunk += wrap("-- module " + modn)
    alloyChunk += wrap("one sig " + modn + " extends Module {")
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
    @constraints = []
    @stores = []
    @creates = []
    @extends = []
    @isAbstract = false
  end

  def exports (op, constraints = {})   
    if constraints.empty?
      @exports << Op.new(op, {:when => Unit.new, :args => []})
    else
      if not constraints.has_key? :args
        constraints[:args] = []
      end
      if not constraints.has_key? :when
        constraints[:when] = Unit.new
      end
      @exports << Op.new(op, constraints)
    end
  end

  def invokes (op, constraints = {})
    if constraints.empty?
      @invokes << Op.new(op, :when => Unit.new) 
    else 
      if not constraints.has_key? :when
        constraints[:when] = Unit.new
      end
      @invokes << Op.new(op, constraints)
    end
  end

  def constraints(*constr)
    @constraints = @constraints + constr   
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
    @creates = @creates + data
  end

  def extends parent
    @extends << parent
  end

  def build name
    Mod.new(name, @exports, @invokes, @constraints, @stores, 
            @creates, @extends, @isAbstract)
  end
end

def mod(name, &block)
  Docile.dsl_eval(ModuleBuilder.new, &block).build name
end
