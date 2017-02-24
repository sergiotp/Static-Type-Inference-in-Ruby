class ClassA
  def method
    return Proc.new { |y|
      next y
    }
  end
  
  def foo
    block = method
    x = block.call(5)
    x = block.call("str")
    x = block.call({})
  end
end