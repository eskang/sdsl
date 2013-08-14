# view.rb
# generic definition of a view

require 'module.rb'

View = Struct.new(:name, :modules, :trusted, :data, :critical)

class View
  def findMod s
    modules.select { |m| m.name == s }
  end
 
  def to_alloy
    # type: opname -> list(modules)
    invokers = {}
    # type: dataname -> list(modules)
    creators = {}
    alloyChunk = ""    
    modules.each do |m|
      alloyChunk += wrap(m.to_alloy)
      m.invokes.each do |o|
        n = o.name.to_s
        if not invokers.has_key? n then invokers[n] = [] end
        invokers[n] << m.name.to_s
      end
      m.creates.each do |d|
        d = d.to_s
        if not creators.has_key? d then creators[d] = [] end
        creators[d] << m.name.to_s
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
    invokeFacts = []
    invokers.each do |k, v|
      invokeFacts << k + ".sender in " + v.join(" + ")
    end
    alloyChunk += writeFacts("invocationFacts", invokeFacts)

    # write facts about data creation
    createFacts = []
    creators.each do |k, v|
      createFacts << "creates." + k + " in " + v.join(" + ")
    end
    alloyChunk += writeFacts("dataCreationFacts", createFacts)

    # write data decls
    dataDecl = []
    data.each do |d|
      alloyChunk += wrap("sig " + d.to_s + " extends Data {}")
    end
    
    # write critical data fact
    if not critical.empty?
      alloyChunk += writeFacts("criticalDataFacts", 
                               ["CriticalData = " + 
                                critical.map { |d| d.to_s }.
                                join(" + ")])
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
    View.new(name, @modules, @trusted, @data, @critical)
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
  sup.exports.each do |o|
    n = o.name
    if opRel.has_key? n 
      matches = sub.exports.select { |o2| o2.name == opRel[n] }      
      if not matches.empty?
        o2 = matches[0]        
        exports << Op.new(mkMixedName(n, o2.name), 
                          #TODO: Fix this to add args
                          :when => And.new(o.constraints[:when],
                                           o2.constraints[:when]))
        next
      end
    end
    exports << o
  end  
  exports
end

def refineInvokes(sup, sub, opRel)
  invokes = []
  sup.invokes.each do |o|
    n = o.name
    if opRel.has_key? n 
      matches = sub.invokes.select { |o2| o2.name == opRel[n] }      
      if not matches.empty?
        o2 = matches[0]        
        invokes << Op.new(mkMixedName(n, o2.name), 
                          #TODO: Fix this to add args                         
                          :when => And.new(o.constraints[:when],
                                           o2.constraints[:when]),
                          :sends => And.new(o.constraints[:sends],
                                            o2.constraints[:sends]))
        next
      end
    end
    invokes << o
  end
  invokes
end

# sup is the module being refined
# sub is the module refining
# sup is a supertype of sub
def refineMod(sup, sub, opRel)
  name = mkMixedName(sup.name, sub.name)
  exports = refineExports(sup, sub, opRel)  
  invokes = refineInvokes(sup, sub, opRel)
  constraints = sup.constraints + sub.constraints
  stores = sup.stores + sub.stores
  creates = sup.creates + sub.creates
  extends = sup.extends + sub.extends
  isAbstract = true

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
    moduleMap[sub] = refinedModule #TODO: too strong, fix later    
  end

  dataMap.update(opMap).update(moduleMap)
end

# returns three maps that represent refinement relations
# 1. map from each datatype in (v1 + v2) to a dataype 
# 2. map from each operation in (v1 + v2) to an operation
# 3. map from each module in (v1 + v2) to a module
def merge(v1, v2, mapping)
  modules = Set.new

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

  View.new(:MergedView, modules, [], [], [])
end

def composeViews(v1, v2, refineRel = {})
  # Given refinement relations, derive a mapping between elements of two views
  mapping = buildMapping(v1, v2, refineRel)

  pp "*** Intermediate Mapping:"
#  pp mapping

  # Construct a new view based on the relations between the two views
  mergeResult = merge(v1, v2, mapping)
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
