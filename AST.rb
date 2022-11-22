class AST
  @@indent = "   "

  def error(msg=nil, line=nil)
    if line
      print "Error: line #{line} ", msg, "\n"
    else
      print "Error: ", msg, "\n" 
    end
    exit 1
  end
end

class Program < AST
  attr_reader :table

  def initialize(blocks, symtable)
    @blocks = blocks
    @table = symtable
  end

  def print_ast()
    @blocks.print_ast(0)
  end

  def semantic_check(table=nil)
    @blocks.semantic_check(nil)
  end

  def evaluate(table=nil)
    @blocks.evaluate
  end
end

class Block < AST
  def initialize(declarations, instructions, table)
    @declarations = declarations
    @instructions = instructions
    @table = table
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Block:"
    @table.print(@@indent*(tabs+1))
    @instructions.print_ast(tabs+1)
  end

  def semantic_check(table)
    @instructions.semantic_check(@table)
  end

  def evaluate(table=nil)
    @instructions.evaluate(@table)
  end

end

class Declare < AST
  attr_reader :var, :type

  def initialize(var, type)
    @var = var
    @type = type
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Declare:"
    @var.each { |v| v.print_ast(tabs+1)} 
  end

  # def to_s
  #   "#{var} #{type}"
  # end

end

class Sequence < AST
  attr_reader :inst1, :inst2

  def initialize(inst1, inst2)
    @inst1 = inst1
    @inst2 = inst2
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Secuenciacion:"
    @inst1.print_ast(tabs+1)
    @inst2.print_ast(tabs+1)
  end

  def semantic_check(table)
    @inst1.semantic_check(table)
    @inst2.semantic_check(table)
  end

  def evaluate(table)
    @inst1.evaluate(table)
    @inst2.evaluate(table)
  end

end

class Iden < AST
  attr_reader :id, :line, :column, :type

  def initialize(id, line, column)
    @id = id
    @line = line
    @column = column
  end

  def to_s
    "#{@id}"
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Ident: #{@id}"
  end

  def semantic_check(table)
    @type = table.get(self)[:type]
  end

  def evaluate(table=nil)
    var = table.get(self)
    var[:value] || (error("variable `#{var[:name].id}` not initialized"))
  end

end

class Assign < AST
  def initialize(var, exp)
    @var = var
    @exp = exp
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Asignacion:"
    puts @@indent*(tabs+1)+"Variable: #{@var}"
    return unless @exp
    @exp.each do |expr|
      expr.print_ast(tabs+1)
    end
  end

  def semantic_check(table)
    sym = table.get(@var)
    line = @var.line
    @exp.each {|e| e.semantic_check(table)}

    if sym[:type].kind_of?(TArray) 
      return if sym[:type] == @exp.first.type
      error("number of elements must be equal to array size", line)\
        unless sym[:type].size == @exp.size
      error("array `#{sym[:name]}` elements must be int", line)\
        unless @exp.all? {|e| e.type == "int"} 
    elsif sym[:control]
      error("`:=` changes control variable `#{sym[:name]}`",line)
    else
      error("#{sym[:type]} variable `#{sym[:name]}` receives "\
            "#{@exp.first.type}", line) unless sym[:type] == @exp.first.type
      error("too many elements for variable `#{sym[:name]}`", line)\
        unless  @exp.size == 1
    end
  end

  def evaluate(table)
    sym = table.get(@var)
    evaluated_exp = @exp.map { |e| e.evaluate(table) }
    case sym[:type]
    when "int"
      sym[:value] = evaluated_exp.first
    when "bool"
      sym[:value] = evaluated_exp.first
    else
      sym[:value] = GArray.new(sym[:type].state, evaluated_exp)
    end
  end

end

class Literal < AST
  attr_reader :type, :line

  def initialize(type, value, line)
    @type = type
    @value = value
    @line = line
  end

  def print_ast(tabs)
    puts @@indent*tabs + "Literal #{@type}: #{@value}"
  end

  def semantic_check(table)
  end

  def evaluate(table=nil)
    case @type
    when "bool"
      "true" == @value ? true : false
    when "int"
      @value.to_i
    else
      @value.undump
    end
  end

  def to_s
    "#{@value}"
  end

end

class UnOp < AST
  attr_reader :type, :line
  def initialize(type, operator, operand, line)
    @type = type
    @operator = operator
    @operand = operand
    @line = line
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Expresión:"
    puts @@indent*(tabs+1)+"operador unario: #{@operator}"
    puts @@indent*(tabs+1)+"operando:"
    @operand.print_ast(tabs+2)
  end

  def semantic_check(table)
    @operand.semantic_check(table)
    case @operator
    when "-"
      error("`#{@operator}` operands must be int", @line) unless @operand.type == "int"
    when "!"
      error("`#{@operator}` operands must be bool", @line) unless @operand.type == "bool"
    end
  end

  def evaluate(table=nil)
    value = @operand.evaluate
    case @operator
    when "-"
      value.send("-@") 
    when "!"
      value.send("!")
    end
  end

end

class BinOp < AST
  attr_reader :type, :line

  def initialize(type, operator, loperand, roperand, line)
    @type = type
    @operator = operator
    @loperand = loperand
    @roperand = roperand
    @line = line
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Expresión:"
    puts @@indent*(tabs+1)+"operador binario: #{@operator}"
    puts @@indent*(tabs+1)+"operando izquierdo:"
    @loperand.print_ast(tabs+2)
    puts @@indent*(tabs+1)+"operando derecho:"
    @roperand.print_ast(tabs+2)
  end

  def semantic_check(table)
    @loperand.semantic_check(table)
    @roperand.semantic_check(table)
    case @operator
    when "+", "-", "*", "/", "%","<", "<=", ">", ">=" 
      unless @loperand.type == @roperand.type && @loperand.type == "int"
        error("`#{@operator}` operands must be int", @line)
      end
    when "/\\", "\\/"
      unless @loperand.type == @roperand.type && @loperand.type == "bool"
        error("`#{@operator}` operands must be bool")
      end
    when "==", "!="
      unless @loperand.type == @roperand.type
        error("`#{@operator}` operands must be same type")
      end
    end
  end

  def evaluate(table=nil)
    left = @loperand.evaluate(table)
    right = @roperand.evaluate(table)
    op = case @operator
         when "/\\"
           "&"
         when "\\/"
           "|"
         else
           @operator
         end

    if @type == :concat
      return left.to_s + right.to_s
    end

    begin
    left.send(op,right)
    rescue 
      error("division by 0", @line)
    exit 1
    end
  end

end

class Output < AST
  def initialize(type, exp)
    @type = type
    @exp = exp
  end

  def print_ast(tabs)
    puts @@indent*tabs+ "#{@type}:"
    @exp.print_ast(tabs+1)
  end

  def semantic_check(table)
    @exp.semantic_check(table)
  end

  def evaluate(table=nil)
    if @type.to_s == "Print"
      print @exp.evaluate(table).to_s
    else
      puts @exp.evaluate(table).to_s
    end
  end

end

class Input < AST
  def initialize(var)
    @var = var
  end

  def print_ast(tabs)
    puts @@indent*tabs+ "Read:"
    @var.print_ast(tabs+1)
  end

  def semantic_check(table)
    sym = table.get(@var)
    line = @var.line
    error("`read` changes control variable `#{sym[:name]}`", line)\
      if sym[:control]
  end

  def evaluate(table)
    sym = table.get(@var)
    value = read(sym[:type])
    sym[:value] = (value.size>1) ? GArray.new(sym[:type].state, value) : value.first
  end

  def read(type)
    regex_int_array = /^\s*(?>[-]{0,1}\d+)\s*(?>,\s*\d+\s*)*$/
    regex_bool = /^\s*(true|false)\s*$/
    size = 1
    case type
    when "int"
      puts "introduce 1 int value"
      f = STDIN.gets
      values =  regex_int_array.match(f).to_s.gsub("\s+","").strip.split(",")
    when "bool"
      puts "introduce 1 bool value"
      f = STDIN.gets
      values =  regex_bool.match(f).to_s.gsub("\s+","").strip.split(",")
    else
      puts "introduce #{type.size} int values"
      size = type.size
      f = STDIN.gets
      values =  regex_int_array.match(f).to_s.gsub("\s+","").strip.split(",")
    end

    error("bad input format", @var.line) unless values.size == size
    values.map do |c|
      if type == "bool"
        (c=="true") ? true : false
      else 
        c.to_i
      end
    end
  end

end

class For < AST
  def initialize(id, exp1, exp2, inst, stable)
    @id = id
    @exp1 = exp1
    @exp2 = exp2
    @inst = inst
    @stable = stable
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Iteración Determinada:"
    puts @@indent*(tabs+1)+"Iterador:"
    @id.print_ast(tabs+2)
    puts @@indent*(tabs+1)+"Límite inferior:"
    @exp1.print_ast(tabs+2)
    puts @@indent*(tabs+1)+"Límite superior:"
    @exp2.print_ast(tabs+2)
    puts @@indent*(tabs+1)+"Instrucción:"
    @inst.print_ast(tabs+2)
  end

  def semantic_check(table)
    @inst.semantic_check(@stable)
  end

  def evaluate(table)
    range = (@exp1.evaluate(table)..@exp2.evaluate(table))
    control_var = @stable.get(@id)
    range.each do |i|
      control_var[:value] = i
      @inst.evaluate(@stable)
    end

  end

end

class Do < AST
  def initialize(cond, inst, guards)
    @cond = cond
    @inst = inst
    @guards = [[@cond,@inst]] + (guards||[])
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Iteración Indeterminada:"
    puts @@indent*(tabs+1)+"Guardia:"
    @cond.print_ast(tabs+2)
    puts @@indent*(tabs+1)+"Instrucción:"
    @inst.print_ast(tabs+2)
    return unless @guards
    @guards.each do |guard,instr|
      puts @@indent*(tabs+1)+"Guardia:"
      guard.print_ast(tabs+2)
      puts @@indent*(tabs+1)+"Instrucción:"
      instr.print_ast(tabs+2)
    end
  end

  def semantic_check(table)
    @cond.semantic_check(table)
    @inst.semantic_check(table)
    error("condition must be bool", @cond.line) unless @cond.type == "bool"

    return unless @guards
    @guards.each do |cond, instr|
      cond.semantic_check(table)
      error("condition must be bool", cond.line) unless cond.type == "bool"
      instr.semantic_check(table)
    end
  end

  def evaluate(table)
    begin
      guards_disyunction = false
      @guards.each do |cond,inst|
        cond_eval = cond.evaluate(table)
        if (cond_eval)
          inst.evaluate(table)
        end
        guards_disyunction ||=  cond_eval
      end
    end while guards_disyunction
  end

end

class Conditional < AST
  def initialize(exp, inst, guards)
    @exp = exp
    @inst = inst
    @guards = guards
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Condicional:"
    puts @@indent*(tabs+1)+"Guardia:"
    @exp.print_ast(tabs+2)
    puts @@indent*(tabs+1)+"Instrucción:"
    @inst.print_ast(tabs+2)
    return unless @guards
    @guards.each do |guard,instr|
      puts @@indent*(tabs+1)+"Guardia:"
      guard.print_ast(tabs+2)
      puts @@indent*(tabs+1)+"Instrucción:"
      instr.print_ast(tabs+2)
    end
  end

  def semantic_check(table)
    @exp.semantic_check(table)
    error("condition must be bool", @exp.line) unless @exp.type == "bool"
    @inst.semantic_check(table)

    return unless @guards
    @guards.each do |cond, instr|
      cond.semantic_check(table)
      error("condition must be bool", cond.line) unless cond.type == "bool"
      instr.semantic_check(table)
    end
  end

  def evaluate(table)
    if (@exp.evaluate(table))
      @inst.evaluate(table)
    end
    return unless @guards

    @guards.each do |guard, instr|
      if (guard.evaluate(table))
        instr.evaluate(table)
      end
    end
    @guars
  end

end

class TArray < AST
  attr_reader :n,:m, :val

  def initialize(n, m)
    @n = n.to_i
    @m = m.to_i
    @val = @n..@m
  end

  def size
    return m - n + 1
  end

  def to_s
    "array[#{@n..@m}]"
  end

  def ==(other)
    other.class == self.class && other.state == state
  end

  def state
    [@n, @m]
  end

  def min
    @n
  end

  def max
    @m
  end

end

class Index < AST
  attr_reader :type

  def initialize(id,exp)
    @id = id
    @exp = exp
    @type = "int"
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Indexación Arreglo:"
    @id.print_ast(tabs+1)
    @exp.print_ast(tabs+1)
  end

  def semantic_check(table)
    table.get(@id)
    @exp.semantic_check(table)
    error("array indices must be int", @exp.line) unless @exp.type == "int"
  end

  def evaluate(table=nil)
    index = @exp.evaluate(table)
    arr = table.get(@id)
    (error("variable `#{arr[:name].id}` not initialized")) unless arr[:value] 
    begin 
      arr[:value][index]
    rescue
      error("index `#{index}` out of bounds", @id.line)
    end
  end

end

class Modif < AST
  attr_reader :type, :value, :line

  def initialize(array,exp1,exp2,line)
    @array = array
    @exp1 = exp1
    @exp2 = exp2
    @type = nil
    @value = nil
    @line = line
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Modificación Arreglo:"
    @array.print_ast(tabs+1)
    @exp1.print_ast(tabs+1)
    @exp2.print_ast(tabs+1)
  end

  def id
    @array.id
  end

  def semantic_check(table)
    if @array.kind_of?(Iden)
      sym = table.get(@array)
      @type = sym[:type]
    else
      @array.semantic_check(table)
      @type = @array.type
    end
    @exp1.semantic_check(table)
    error("array indices must be int", @exp1.line) unless @exp1.type == "int" 
    @exp2.semantic_check(table)
    error("modification values must be int", @exp2.line) unless @exp2.type == "int" 
  end

  def evaluate(table=nil)
    index = @exp1.evaluate(table)
    value = @exp2.evaluate(table)
    if @array.kind_of?(Iden)
      array = table.get(@array)[:value].clone
      begin
        array[index]=value
      rescue
        error("index `#{index}` out of bounds", @line)
      end
    else
    array = @array.evaluate(table).clone
      begin
        array[index]=value
      rescue
        error("index `#{index}` out of bounds", @line)
      end
    end
    array
  end

end

class Atoi < AST
  attr_reader :type

  def initialize(exp)
    @exp = exp
    @type = "int"
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Atoi:"
    @exp.print_ast(tabs+1)
  end

  def semantic_check(table)
    @exp.semantic_check(table)
    error("`atoi` argument must be array", @exp.line) unless @exp.type.kind_of?(TArray)
    error("`atoi` argument size must be 1", @exp.line) unless @exp.type.size==1
  end

  def evaluate(table)
    var = @exp.evaluate(table)
    var.first
  end

end

class Size < AST
  attr_reader :type

  def initialize(exp)
    @exp = exp
    @type = "int"
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Size:"
    @exp.print_ast(tabs+1)
  end

  def semantic_check(table)
    @exp.semantic_check(table)
    error("`size` argument must be array", @exp.line) unless @exp.type.kind_of?(TArray)
  end

  def evaluate(table)
    @exp.evaluate(table).size
  end
end

class Min < AST
  attr_reader :type

  def initialize(exp)
    @exp = exp
    @type = "int"
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Min:"
    @exp.print_ast(tabs+1)
  end

  def semantic_check(table)
    @exp.semantic_check(table)
    error("`min` argument must be array", @exp.line) unless @exp.type.kind_of?(TArray)
  end

  def evaluate(table)
    @exp.evaluate(table).min
  end

end

class Max < AST
  attr_reader :type
  def initialize(exp)
    @exp = exp
    @type = "int"
  end

  def print_ast(tabs)
    puts @@indent*tabs+"Max:"
    @exp.print_ast(tabs+1)
  end
  
  def semantic_check(table)
    @exp.semantic_check(table)
    error("`max` argument must be array", @exp.line) unless @exp.type.kind_of?(TArray)
  end

  def evaluate(table)
    @exp.evaluate(table).max
  end

end

class GArray < AST
  attr_accessor :value

  def initialize(limits, val)
    @limits = limits
    @val = val
    @range = Range.new(*limits)
    @value = @range.to_a.zip(val)
  end

  def to_s
    ((@value.map { |c| c.join(":")  } ).join(", ")).to_s
  end

  def first
    @value.first[1]
  end

  def size
    @range.size
  end

  def max
    @range.last
  end

  def min
    @range.first
  end

  def []=(ind,val)
    index = @range.find_index(ind) 
    raise RuntimeError unless index
    @value[index][1] = val
  end

  def [](ind)
    index = @range.find_index(ind) 
    raise RuntimeError unless index
    @value[index][1]
  end

  # No es la mejor forma de hacer una deep copy, pero funciona
  def clone
    return Marshal.load(Marshal.dump(self))
  end

end

