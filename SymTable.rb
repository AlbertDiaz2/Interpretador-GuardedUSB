class SymTable
  attr_accessor  :prev, :hash

  def initialize(prev)
    @prev = prev
    @hash = Hash.new
  end

  def put(id_list)
    declare_list = read_declare(id_list)
    declare_list.each do |v,t,val,c|
      error(v.line, v, "already declared") if @hash[v.to_s]
      @hash[v.to_s] = {name: v, type:t, value: val, control:c }
    end
  end

  def read_declare(declares)
    if declares.is_a?(Sequence)
      read_declare(declares.inst1) + read_declare(declares.inst2)
    elsif declares.is_a?(Iden)
      [ [declares, "int", nil, :control ] ]
    else
      declares.var.zip(declares.type.cycle)
    end
  end


  def print(indent)
    @hash.each do |h,v|
      puts indent + "Variable: #{h} | #{v[:type]} | #{v[:value]}"
    end
  end

  def get(var)
    table = self
    result = nil
    while table
      if (result = table.hash[var.id])
        return result 
      end
      table = table.prev
    end
    error(var.line, var, "undeclared")
  end

  def error(line, v, msg)
    puts "Error: line #{line} Variable `#{v}` #{msg}"
    exit 1
  end

  def to_s
    "#{@hash.keys}"
  end

end
