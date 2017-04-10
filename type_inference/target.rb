class ClassA
  
  def qux
    return "str"
  end
  
  def foo(s, proc)
    if s.start_with?("i")
      return []
    elsif s.start_with("j")
      return qux
    elsif s.start_with("k")
      6
    else
      a = proc.call("nothing")
      return a
    end
  end
end

class ClassB
  def bar
    a = ClassA.new
    p = Proc.new{|y|
      puts y
      obj = Object.new
      obj
    }
    x = a.foo("something", p)
  end
end