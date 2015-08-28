class InternalMethodInvocation
  attr_reader :class_name, :method_name, :params

  def initialize(class_name, method_name, params=nil)
    @class_name = class_name
    @method_name = method_name
    @params = params
  end
end
