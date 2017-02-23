module Archruby
  module Ruby
    module TypeInference
      module Ruby

        class InternalMethodInvocation
          attr_reader :class_name, :method_name, :params, :linenum, :var_name, :new_params, :var_assigned

          def initialize(class_name, method_name, params=nil, linenum = nil, var_name=nil, new_params=nil, var_assigned = nil)
            if(class_name.class == Array)
              @class_name = class_name[0]
            else
              @class_name = class_name
            end
            @method_name = method_name
            @params = params
            @linenum = linenum
            @var_name = var_name
            @new_params = new_params
            @var_assigned = var_assigned
          end
        end

      end
    end
  end
end
