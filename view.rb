# view.rb
# generic definition of a view

require 'module.rb'

View = Struct.new(:name, :modules, :trusted, :data, :critical, :assumptions,
                  :protected, :ctx)

class View
  def findMod s
    (modules.select { |m| m.name == s })[0]
  end
 
  def findData s
    (data.select { |d| d.name == s})[0]
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

    # for pretty printing purposes only
    ctx[:nesting] = 0

    alloyChunk = ""
    
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
        if not creators.has_key? d then creators[d] = [] end
        creators[d] << modn
        superdata = findData(d).extends
        if not superdata == :Data
          if not creators.has_key? superdata then creators[superdata] = [] end
          creators[superdata] << modn
        end
      end
    end

    # write facts about trusted modules
    if not trusted.empty?
      alloyChunk += writeFacts("trustedModuleFacts", 
                               ["TrustedModule = " + 
                                trusted.map { |m| m.name }.
                                join(" + ")])
    end

    if not protected.empty?
      alloyChunk += writeFacts("protectedModuleFacts", 
                               ["ProtectedModule = " + 
                                protected.map { |m| m.name }.
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
      alloyChunk += writeComment("operation #{k}")
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
      dn = d.name

      if creators.has_key? dn
        dataFacts << "creates.#{dn} in " + creators[dn].join(" + ")
      else 
        if critical.include? d
          dataFacts << "no creates.#{dn}"
        end
      end     
    end

    alloyChunk += writeFacts("dataFacts", dataFacts)

    
    # write data decls
    alloyChunk += writeComment("datatype declarations")
    dataDecl = []
    data.each do |d|
      alloyChunk += d.to_alloy(ctx)
    end
    alloyChunk += wrap("sig OtherData extends Data {}{ no fields }")
    
    # write critical data fact
    if not critical.empty?
      alloyChunk += writeFacts("criticalDataFacts", 
                               ["CriticalData = " + 
                                critical.map { |d| d.to_s }.
                                join(" + ")])
    end

    # write assumptions
    if not assumptions.empty?
      alloyChunk += writeFacts("assumptions", 
                               assumptions.map { |a| a.to_alloy(ctx)})
    end
    
    #TODO: This is a hack; need a better way
    # ctx.each do |k, v|
    #   if not (k == :op or k == :nesting)
    #     alloyChunk = alloyChunk.gsub("(" + k.to_s + ")", 
    #                                  "(" + v.to_a.join("+") + ")")
    #   end
    # end

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
    @assumptions = []
    @protected = []
    @ctx = {}
  end
  
  def data(*data)
    @data += data.map{ |d| 
      if d.is_a? Datatype
        d
      else 
        Datatype.new(d, [], :Data, false) 
      end
    }
  end

  def critical(*data)
    @critical += data
  end

  def modules(*mods)
    @modules += mods
  end

  def trusted(*mods)
    @trusted += mods
  end

  def assumes(*assums)
    @assumptions += assums
  end

  def protected(*mods)
    @protected += mods
  end

  def build name
    View.new(name, @modules, @trusted, @data, @critical, @assumptions, 
             @protected, @ctx)
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
                          {:when => (o.constraints[:when] + 
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
                          {:when => (o.constraints[:when] + 
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

def abstractExports(m1, m2, opRel)
  exports = []
  m2Exports = m2.exports.dup
  m1.exports.each do |o|
    n = o.name
    if opRel.has_key? n 
      matches = m2.exports.select { |o2| o2.name == opRel[n] }      
      if not matches.empty?
        o2 = matches[0]   
        exports << Op.new(n, #mkMixedName(n, o2.name), 
                          {:when => union(o.constraints[:when],
                                          o2.constraints[:when]),
                            :args => myuniq(o.constraints[:args] + 
                                            o2.constraints[:args])}, o, o2)
        m2Exports.delete(o2)
        next
      end
    end
    exports << o
  end  
  exports + m2Exports  
end

def abstractInvokes(m1, m2, opRel)
  invokes = []
  m2Invokes = m2.invokes.dup
  m1.invokes.each do |o|
    n = o.name
    
    if opRel.has_key? n 
      matches = m2.invokes.select { |o2| o2.name == opRel[n] }    
      if not matches.empty?
        o2 = matches[0]     
        invokes << Op.new(n, #mkMixedName(n, o2.name),
                          {:when => union(o.constraints[:when],
                                          o2.constraints[:when])},
                          o, o2)
        m2Invokes.delete(o2)
        next
      end
    end
    invokes << o
  end
  invokes + m2Invokes
end

# sup is the module being refined
# sub is the module refining
# sup is a supertype of sub
def refineMod(sup, sub, opRel)
  name = mkMixedName(sup.name, sub.name)
  # refinement
  exports = refineExports(sup, sub, opRel)  
  invokes = refineInvokes(sup, sub, opRel)
  assumptions = sub.assumptions + sup.assumptions
  stores = sub.stores + sup.stores
  creates = sub.creates + sup.creates
  extends = sup
  isAbstract = false
  isUniq = sup.isUniq  #TODO: Fix it later

  Mod.new(name, exports, invokes, assumptions, stores, creates, 
          extends, isAbstract, isUniq)
end

def mergeMod(m1, m2, opRel)
  name = m1.name #mkMixedName(m1.name, m2.name)
  # abstraction
  exports = abstractExports(m1, m2, opRel)  
  invokes = abstractInvokes(m1, m2, opRel)
  assumptions = m2.assumptions + m1.assumptions
  stores = myuniq(m2.stores + m1.stores)
  creates = m2.creates + m1.creates
  extends = m1
  isAbstract = false
  isUniq = m1.isUniq #TODO: Fix it later

  Mod.new(name, exports, invokes, assumptions, stores, creates, 
          extends, isAbstract, isUniq)
end

def buildMapping(v1, v2, refinementRel)
  dataMap = {}
  opMap = {}
  moduleMap = {}
  
  opRel = refinementRel[:Op]

  dataRel = refinementRel[:Data]
  dataRel.each do |from, to|
    sub = v1.findData(from)
    sup = v2.findData(to)    
    dataMap[from] = Datatype.new(sub.name, sub.fields, sup.name, false)
    dataMap[to] = Datatype.new(sup.name, sup.fields, :Data, true)
  end

  modRel = refinementRel[:Module]
  modRel.each do |from, to|
    sup = v1.findMod(from)
    sub = v2.findMod(to)
    if sup.name == sub.name      
      newMod = mergeMod(sup, sub, opRel)
    else
      newMod = refineMod(sup, sub, opRel)
    end
    moduleMap[sup] = newMod
    sup.isAbstract = true
    moduleMap[sub] = newMod #TODO: too strong, fix later    
  end

  dataMap.update(opMap).update(moduleMap)
end

# returns three maps that represent refinement relations
# 1. map from each datatype in (v1 + v2) to a dataype 
# 2. map from each operation in (v1 + v2) to an operation
# 3. map from each module in (v1 + v2) to a module
def merge(v1, v2, mapping, opRel)
  modules = []
  ctx = {}

  opRel.each do |from, to|
    if from == to 
      o = from.to_s
    else 
      o = mkMixedName(from, to).to_s
    end

    if ctx[from].nil? then ctx[from] = Set.new() end
    if ctx[to].nil? then ctx[to] = Set.new() end    
    ctx[from].add(o)
    ctx[to].add(o)
  end

  (v1.modules + v2.modules).each do |m| 
    if mapping.has_key? m 
      modules << mapping[m]
    else
      modules << m.clone
    end
  end
  modules = myuniq(modules)

  # trusted modules
  trusted = (v1.trusted + v2.trusted).map{ |m| if mapping.has_key? m then 
                                                 mapping[m] 
                                               else 
                                                 m end}
  # data
  data = (v1.data + v2.data).map { |d| if mapping.has_key? d.name then 
                                         mapping[d.name]
                                       else 
                                         d
                                       end}
  otherData = []
  data.each do |d|
    dn = d.name
    i = data.find_index { |d2| d2.extends == dn }
    if i then
      otherData << Datatype.new(("Other#{dn}").to_sym, [], dn, false) 
    end
  end
  data += otherData
  data = myuniq(data)

  # all exported operations
  allExports = modules.inject([]) {|r, m| r + m.exports}
  
  modules.each do |m|
    newInvokes = []
    m.invokes.each do |i|
      n = i.name
      c = i.constraints
      relevantExports =
        allExports.select {|e| (n == e.name or
                                ((not e.parent.nil?) and 
                                 n == e.parent.name) or
                                ((not e.child.nil?) and 
                                 n == e.child.name))}
      relevantExports.each do |e|
        newInvokes << Op.new(e.name, c)
      end
    end
    m.invokes = newInvokes
  end

  View.new(:MergedView, modules, trusted, data, v1.critical, 
           v1.assumptions + v2.assumptions, v1.protected, ctx)
end

def composeViews(v1, v2, refineRel = {})
  puts "*** Attempting to merge #{v1.name} and #{v2.name} ***:"
  # Given refinement relations, derive a mapping between elements of two views
  mapping = buildMapping(v1, v2, refineRel)

#  pp "*** Intermediate Mapping:"
#  pp mapping

  # Construct a new view based on the relations between the two views
  mergeResult = merge(v1, v2, mapping, refineRel[:Op])

  puts "*** Successfully merge #{v1.name} and #{v2.name} ***:"
  puts ""
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
