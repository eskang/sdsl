# view.rb
# generic definition of a view

require 'module.rb'

View = Struct.new(:name, :modules, :trusted, :data, :critical, :ctx)

class View
  def findMod s
    modules.select { |m| m.name == s }
  end
 
  def to_alloy
    # type: opname -> list(modules)
    invokers = {}
    # type: opname -> list(modules)
    exporters = {}
    # type: dataname -> list(modules)
    creators = {}
    decls = {}  # declarations
    sigfacts = {} # signature facts 
    fields = {} 

    alloyChunk = ""
    
    pp "###############################"
    pp ctx
    pp "###############################"

    # all exported operations
    allExports = modules.inject([]) {|r, m| r + m.exports}   
    # all invoked operations
    allInvokes = modules.inject([]) {|r, m| r + m.invokes.map {|i| i.name}}
    allInvokes.each do |i|
      if not ctx.has_key? i then ctx[i] = Set.new([]) end
      ctx[i].merge( allExports.select {|e| 
                      (i == e.name or 
                       ((not e.parent.nil?) and i == e.parent.name) or 
                       ((not e.child.nil?) and i == e.child.name))}.map {|e| e.name.to_s})
    end

    pp "******************************"
    pp ctx
    pp "******************************"

    modules.each do |m|
      modn = m.name.to_s
      alloyChunk += wrap(m.to_alloy(ctx))
      # invocations
      m.invokes.each do |o|
        n = o.name.to_s

        if not invokers.has_key? n then invokers[n] = [] end
        invokers[n] << modn
      end

      # exports
      m.exports.each do |o|
        n = o.name.to_s
        decls[n] = "Op"
        if not exporters.has_key? n then exporters[n] = [] end
        exporters[n] << modn
        # op arguments
        fields[n] = []
        sigfacts[n] = []
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

      # data creations
      m.creates.each do |d|
        d = d.to_s
        if not creators.has_key? d then creators[d] = [] end
        creators[d] << modn
      end
    end
    
    # write facts about trusted modules
    if not trusted.empty?
      alloyChunk += writeFacts("trustedModuleFacts", 
                               ["TrustedModule = " + 
                                trusted.map { |m| m.name }.
                                join(" + ")])
    end

    # write facts about invocation
    invokers.each do |k, v|
      if sigfacts.has_key? k
        sigfacts[k] << "sender in " + v.join(" + ")
      end
    end

    # write facts about exports
    exporters.each do |k, v|
      if sigfacts.has_key? k
        sigfacts[k] << "receiver in " + v.join(" + ")
      end
    end

    # write op declarations
    decls.each do |k, v|
      alloyChunk += wrap("-- operation " + k)
      alloyChunk += wrap("sig " + k + " extends " + v + " {")
      # fields      
      fields[k].each do |f|
        alloyChunk += wrap(f.to_alloy(ctx) + ",", 1)
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

    # write facts about data creation
    dataFacts = []
    data.each do |d|
      dn = d.to_s
      if creators.has_key? dn
        dataFacts << "creates." + dn + " in " + creators[dn].join(" + ")
      else 
        dataFacts << "no creates" + dn
      end     
    end
    alloyChunk += writeFacts("dataFacts", dataFacts)

    # write data decls
    dataDecl = []
    data.each do |d|
      alloyChunk += wrap("sig " + d.to_s + " extends Data {}")
    end
    alloyChunk += wrap("sig OtherData extends Data {}")
    
    # write critical data fact
    if not critical.empty?
      alloyChunk += writeFacts("criticalDataFacts", 
                               ["CriticalData = " + 
                                critical.map { |d| d.to_s }.
                                join(" + ")])
    end
    
    #TODO: This is a hack; need a better way
    ctx.each do |k, v|
      alloyChunk = alloyChunk.gsub("(" + k.to_s + ")", 
                                   "(" + v.to_a.join("+") + ")")
    end

    alloyChunk
  end
  # View
end

class ViewBuilder 
  def initialize 
    @modules = []
    @trusted = []
    @data = []
    @critical = []
    @ctx = {}
  end
  
  def data(*data)
    @data = @data + data
  end

  def critical(*data)
    @critical = @critical + data
  end

  def modules(*mods)
    @modules = @modules + mods
  end

  def trusted(*mods)
    @trusted = @trusted + mods
  end

  def build name
    View.new(name, @modules, @trusted, @data, @critical, @ctx)
  end
end

def view(name, &block)
  Docile.dsl_eval(ViewBuilder.new, &block).build name
end

def mapping(name, &block)
  Docile.dsl_eval(MappingBuilder.new, &block).build name
end

# precond: both sup and sub are symbols
def mkMixedName(sup, sub) 
  (sup.to_s + "_" + sub.to_s).to_sym
end

def refineExports(sup, sub, opRel) 
  exports = []
  subExports = sub.exports.dup
  sup.exports.each do |o|
    n = o.name
    if opRel.has_key? n 
      matches = sub.exports.select { |o2| o2.name == opRel[n] }      
      if not matches.empty?
        o2 = matches[0]   
        exports << Op.new(mkMixedName(n, o2.name), 
                          {:when => conj(o.constraints[:when],
                                        o2.constraints[:when]),
                            :args => (o.constraints[:args] + 
                                      o2.constraints[:args])}, o, o2)
        subExports.delete(o2)
        next
      end
    end
    exports << o
  end  
  exports + subExports
end

def refineInvokes(sup, sub, opRel)
  invokes = []
  subInvokes = sub.invokes.dup
  sup.invokes.each do |o|
    n = o.name
    if opRel.has_key? n 
      matches = sub.invokes.select { |o2| o2.name == opRel[n] }    
      if not matches.empty?
        o2 = matches[0]     
        invokes << Op.new(mkMixedName(n, o2.name), 
                          {:when => conj(o.constraints[:when],
                                         o2.constraints[:when])},
                          o, o2)
        subInvokes.delete(o2)
        next
      end
    end
    invokes << o
  end
  invokes + subInvokes
end

# sup is the module being refined
# sub is the module refining
# sup is a supertype of sub
def refineMod(sup, sub, opRel)
  name = mkMixedName(sup.name, sub.name)
  exports = refineExports(sup, sub, opRel)  
  invokes = refineInvokes(sup, sub, opRel)
  constraints = sub.constraints + sup.constraints
  stores = sub.stores + sup.stores
  creates = sub.creates + sup.creates
  extends = sup
  isAbstract = false

  Mod.new(name, exports, invokes, constraints, stores, creates, 
          extends, isAbstract)
end

# sup is the op being refiend
# sub is the op refining
# sup is a supertype of sub
def refineOp(sup, sub)
end

def buildMapping(v1, v2, refinementRel)
  dataMap = {}
  opMap = {}
  moduleMap = {}
  
  opRel = refinementRel[:Op]

  dataRel = refinementRel[:Data]
  dataRel.each do |from, to| 
    refinedData = RefinedData.new(to, from)
    dataMap[from] = refinedData    
  end

  modRel = refinementRel[:Module]
  modRel.each do |from, to|
    sup = v1.findMod(from)[0]
    sub = v2.findMod(to)[0]
    refinedModule = refineMod(sup, sub, opRel)
    moduleMap[sup] = refinedModule
    sup.isAbstract = true
    moduleMap[sub] = refinedModule #TODO: too strong, fix later    
  end

  dataMap.update(opMap).update(moduleMap)
end

# returns three maps that represent refinement relations
# 1. map from each datatype in (v1 + v2) to a dataype 
# 2. map from each operation in (v1 + v2) to an operation
# 3. map from each module in (v1 + v2) to a module
def merge(v1, v2, mapping, opRel)
  modules = Set.new
  ctx = {}
  
  opRel.each do |from, to|
    o = mkMixedName(from, to).to_s
    if ctx[from].nil? then ctx[from] = Set.new() end
    if ctx[to].nil? then ctx[to] = Set.new() end    
    ctx[from].add(o)
    ctx[to].add(o)
  end

  v1.modules.each do |m| 
    if mapping.has_key? m 
      modules.add(mapping[m])
    else
      modules.add(m)
    end
  end
  
  v2.modules.each do |m|
    if mapping.has_key? m
      modules.add(mapping[m])
    else
      modules.add(m)
    end
  end

  View.new(:MergedView, modules, [], v1.data + v2.data, [], ctx)
end

def composeViews(v1, v2, refineRel = {})
  # Given refinement relations, derive a mapping between elements of two views
  mapping = buildMapping(v1, v2, refineRel)

  pp "*** Intermediate Mapping:"
#  pp mapping

  # Construct a new view based on the relations between the two views
  mergeResult = merge(v1, v2, mapping, refineRel[:Op])
  pp "*** Merge Result ***:"
#  pp mergeResult
  mergeResult
end

# Mapping = Struct.new(:name, :views, :modMap, :modOp, :modData)

# class MappingBuilder
#   def views(*vs)
#     if !@views then
#       @views = []
#     end
#     @views + vs
#   end
  
#   def modules(mappings = {})
#     if !@modMap then
#       @modMap = []
#     end
#     @modMap.update(mappings)
#   end 

#   def ops(mappings = {})
#     if !@modOp then
#       @modOp = []
#     end
#     @modOp.update(mappings)
#   end 

#   def data(mappings = {})
#     if !@modData then
#       @modData = []
#     end
#     @modData.update(mappings)
#   end 
    
#   def build name
#     Mapping.new(name, @views, @modMap, @modOp, @modData)
#   end
# end
