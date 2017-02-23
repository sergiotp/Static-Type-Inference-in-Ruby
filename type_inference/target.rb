def test(x)
 a = 5
 x.call
end


x = lambda do 
  next Object.new 
  end
puts test(x).class



