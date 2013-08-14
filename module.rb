# mod.rb
# TODO: Data
#
require 'rubygems'
require 'docile'
require 'myutils.rb'

Mod = Struct.new(:name, :exports, :invokes, :constraints, 
                 :stores, :creates,
                 :extends, :isAbstract)
Op = Struct.new(:name, :constraints)

class Mod
  def to_alloy
    # (s1, s2) in decls => sig s1 extends s2
    decls = {}
    sigfacts = {}
    facts = []
    fields = {}
    alloyChunk = ""

    modn = name.to_s    
    # module declaration
    decls[modn] = "Module"
    sigfacts[modn] = []
    fields[modn] = stores

    exports.each do |o|
      n = o.name.to_s
      c = o.constraints[:when].to_alloy
      decls[n] = "Op"
      # receiver constraint
      sigfacts[n] = []
      sigfacts[n] << "receiver in " + modn
      # export constraint
      if not c == UNIT 
        f = "all o : this.receives[" + n + "] | " + c
        sigfacts[modn] << f
      end
      # op arguments
      fields[n] = []
      args = []
      o.constraints[:args].each do |arg|
        if not arg.is_a? Rel
          arg = Item.new(arg, :Data)
        end   
        fields[n] << arg
        args << arg.to_s
      end
      if not args.empty?
        sigfacts[n] << "args = " + args.join(" + ")
      end
    end

    invokes.each do |o|
      n = o.name.to_s
      c1 = o.constraints[:when].to_alloy
      
      if not c1 == UNIT
        f1 = "all o : this.sends[" + n + "] | " + c1
        sigfacts[modn] << f1
      end

      c2 = o.constraints[:sends].to_alloy  
      if not c2 == UNIT
        f2 = "all o : this.sends[" + n + "] | " + c2
        sigfacts[modn] << f2
      end
    end

    # write Alloy expressions

    # declarations 
    decls.each do |k, v| 
      if k == modn then alloyChunk += "one " end      
      alloyChunk += wrap("sig " + k + " extends " + v + " {")
      # fields      
      fields[k].each do |f|
        alloyChunk += wrap(f.to_alloy + ",", 1)
      end
      alloyChunk += "}"
      # signature facts
      if sigfacts.has_key? k
        alloyChunk += wrap("{")
        sigfacts[k].each do |f|
          alloyChunk += wrap(f, 1)
        end
        alloyChunk += wrap("}")
      end
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
      @invokes << Op.new(op, :when => Unit.new, 
                         :sends => Unit.new)
    else 
      if not constraints.has_key? :sends
        constraints[:sends] = Unit.new
      end
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
