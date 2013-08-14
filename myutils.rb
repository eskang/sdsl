# myutils.rb
# misc. utility stuff
#
# TODO: decisions to mull over 
# - just use symbols for data?
#

require 'PP'

DOT_FILE = "out.dot"
ALLOY_FILE = "out.als"
FONTNAME = "courier"
UNIT = "UNIT"
ALLOY_CMDS = "
run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 5 but 9 Data, 10 Step, 9 Op

check Confidentiality {
   Confidentiality 
} for 5 but 9 Data, 10 Step, 9 Op

check Integrity {
   Integrity
} for 5 but 9 Data, 10 Step, 9 Op
"

# String utils
def wrap(s, t=0)  
  ("\t"*t) + s + "\n"
end

def append(s1, s2)
  s1 + s2 + "\n"
end

def enclose s
  "(" + s + ")"
end

def writeFacts(fname, facts)
  if facts.empty? 
    ""
  else 
    str = wrap("fact " + fname + " {")
    facts.each do |f|
      str += wrap(f, 1)
    end
    str += wrap("}")
  end
end

def dotModule m 
  "#{m.name} [shape=component];"
end

def dotOp o
  "#{o.name} [shape=ellipse];"
end

def writeDot mods 
  f = File.new(DOT_FILE, 'w')
  f.puts "digraph g {"
  f.puts 'graph[fontname="' + FONTNAME + '"]'
  f.puts 'node[fontname="' + FONTNAME + '"]'
  f.puts 'edge[fontname="' + FONTNAME + '"]'
  mods.each do |m|
    f.puts(dotModule m)
    m.exports.each do |e|
      f.puts(dotOp e)
      f.puts("#{m.name} -> #{e.name} [dir=none,color=red];")
    end
    m.invokes.each do |i|
      f.puts(dotOp i)
      f.puts("#{m.name} -> #{i.name};")
    end
  end
  f.puts "}"
  f.close
end

def dumpAlloy v 
  f = File.new(ALLOY_FILE, 'w')
  # headers
  f.puts "open models/basic"
  f.puts
  f.puts v.to_alloy
  # footers
  f.puts
  f.puts ALLOY_CMDS
  f.close
end

def drawView v 
  writeDot v.modules
end

#########################################
# Relations
class Rel
end

# Unary rel with multiplicity lone
class Item < Rel
  def initialize(n, t)
    @name = n
    @type = t
  end
  def to_s
    @name.to_s
  end
  def to_alloy
    @name.to_s + " : lone " + @type.to_s
  end
end
def item(n, t)
  Item.new(n, t)
end

# Alloy set
class Bag < Rel
  def initialize(n, t)
    @name = n
    @type = t
  end
  def to_s
    @name.to_s
  end
  def to_alloy
    @name.to_s + " : set " + @type.to_s
  end
end
def set(n, t)
  Bag.new(n, t)
end

# Functions
class Map < Rel
  def initialize(n, t1, t2)
    @name = n
    @type1 = t1
    @type2 = t2
  end
  def to_s
    @name.to_s
  end
  def to_alloy
    @name.to_s + " : " + @type1.to_s + " -> " + @type2.to_s  
  end
end
def contains(m, i)
  if not m.is_a? Expr then m = expr(m) end
  if not i.is_a? Expr then i = expr(i) end
  exists(nav(m, i))  
end

# Expressions

class Expr
end

class AtomicExpr < Expr
  def initialize(e)
    @e = e
  end
  def to_s
    @e.to_s
  end
  def to_alloy
    @e.to_s
  end
end
def expr(e)
  AtomicExpr.new(e)
end

class Intersect < Expr
  def initialize(e1, e2)
    @e1 = e1
    @e2 = e2
  end
  def to_s
    @e1 + " /\ " + @e2
  end
  def to_alloy
    enclose(@e1.to_alloy + " & " + @e2.to_alloy)
  end
end
def intersect(e1, e2)
  Intersect.new(e1, e2)
end

# Navigation expr
class Nav < Expr
  def initialize(m, i)
    @map = m
    @index = i
  end
  def to_s
    @map + "[" + @index + "]"
  end
  def to_alloy
    @map.to_alloy + "[" + @index.to_alloy + "]"
  end
end
def nav(m, i)
  if not m.is_a? Expr then m = expr(m) end
  if not i.is_a? Expr then i = expr(i) end  
  Nav.new(m, i)
end

class Join < Expr
  def initialize(r, c)
    @rel = r
    @col = c
  end
  def to_s
    @rel + "." + @col
  end
  def to_alloy
    @rel.to_alloy + "." + @col.to_alloy
  end
end
def join(r, c)
  Join.new(r, c)
end

def arg(arg, op = nil)
  if not op 
    join(expr(:o), expr(arg))
  else 
    join(op, expr(arg))
  end
end

def trig 
  join(expr(:o), expr(:trigger))
end

#########################################
# Formulas
class Formula 
end

class AlloyFormula < Formula
  attr_reader :exp
  def initialize(f)
    @exp = f
  end
  def to_s
    exp
  end
  def to_alloy
    exp
  end
end
def af(f)
  AlloyFormula.new(f)
end

class Unit < Formula
  def to_s
    UNIT
  end
  def is_unit?
    true
  end
  def to_alloy
    UNIT
  end
end

class Exists < Formula
  def initialize(e)
    @expr = e
  end  
  def to_s
    "Some(" + e + ")"
  end
  def to_alloy
    enclose("some " + @expr.to_alloy)
  end
end
def exists(e)
  Exists.new(e)
end 

class And < Formula
  attr_accessor :left, :right
  def initialize(f1, f2)
    @left = f1
    @right = f2
  end
  def to_s
    "And(" + left + "," + right + ")"
  end

  def to_alloy
    lformula = left.to_alloy
    rformula = right.to_alloy
    if lformula == UNIT or rformula == UNIT
      if lformula = UNIT then expr = rformula end
      if rformula = UNIT then expr = lformula end
      expr
    else      
      enclose(lformula) + " and " + enclose(rformula)
    end
  end
end
def conj(f1, f2)
  And.new(f1, f2)
end

class Or < Formula
  attr_accessor :left, :right
  def initialize(f1, f2)
    @left = f1
    @right = f2
  end

  def to_s
    "Or(" + left + "," + right + ")"
  end

  def to_alloy
    lformula = left.to_alloy
    rformula = right.to_alloy    
    if lformula == UNIT or rformula == UNIT
      raise "An invalid OR expression: OR(" + lformula + "," + rformula + ")"
    else      
      enclose(lformula) + " or " + enclose(rformula)
    end
  end
end
def disj(f1, f2)
  Or.new(f1, f2)
end

class Equals < Formula
  def initialize(e1, e2)
    @left = e1
    @right = e2
  end

  def to_s
    "Equals(" + @left + "," + @right + ")"
  end

  def to_alloy
    enclose(@left.to_alloy + " = " + @right.to_alloy)
  end
end

def triggeredBy(t)
  if not t.is_a? Expr then t = expr(t) end  
  exists(intersect(trig,t))
end

def equals(e1, e2)
  Equals.new(e1, e2)
end