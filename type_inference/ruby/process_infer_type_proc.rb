module Archruby
  module Ruby
    module TypeInference
      module Ruby
        class ProcessInferTypeProc < SexpInterpreter
          
                   
          def self.infer_proc_calls(proc, params, method, all_classes, var_assigned)
            var_args = proc.args.keys
            for i in 0..var_args.size - 1
              proc.var_types[var_args[i]] ||= Set.new
              proc.var_types[var_args[i]].add(params[i])
            end
            
            while(proc.explicit_return_exps.size > 0)
              exp = proc.explicit_return_exps.pop
              types = Ruby::ProcessInferType.new(exp, proc.var_types, proc.var_to_analyse, clazz, all_classes).parse
              proc.explicit_return_types ||= Set.new
              proc.explicit_return_types.merge(types)
              method.var_types[var_assigned] ||= Set.new
              method.var_types[var_assigned].merge(types)
            end
            
            proc.static_var_to_analyse.each do |var_name, exps|
              while(exps.size > 0)
                exp = exps.pop
                types = Ruby::ProcessInferType.new(exp, proc.var_types, proc.var_to_analyse, clazz, all_classes).parse
                proc.static_var_types[var_name] ||= Set.new
                proc.static_var_types[var_name].merge(types)
                proc.clazz.var_types[var_name] ||= Set.new  
                proc.clazz.var_types[var_name].merge(types)
              end
            end
            
          end
          
          def initialize(exp, var_types, var_to_analyse, class_definition, all_classes)
            super()
            @var_types = var_types
            @var_to_analyse = var_to_analyse
            @class_definition = class_definition
            @all_classes = all_classes
            @ast = exp            
          end
          
          def parse
            process(@ast)
            @types
          end

          def update_types(types_set, method_called)
            @types = Set.new
            types_set.each do |class_name|
              if(@all_classes.has_key?(class_name))
                @all_classes[class_name].all_methods.each do |method|
                  if(method.method_name == method_called)
                    Archruby::Ruby::TypeInference::Ruby::ProcessInferType.infer_return_method(method, @all_classes[class_name], @all_classes)
                    @types = method.return_types
                  end
                end
              end
            end
          end

          def process_ivar(exp)
            @types = Set.new
            if(@class_definition.var_types.has_key?(exp[1]))
              @types = @class_definition.var_types[exp[1]]
            end
            if(@class_definition.var_to_analyse.has_key?(exp[1]))
              while(@class_definition.var_to_analyse[exp[1]].size > 0)
                exp_to_analyse = @class_definition.var_to_analyse[exp[1]].pop
                types = Ruby::ProcessInferType.new(@var_to_analyse[exp[1]], @var_types, @var_to_analyse, @class_definition, @all_classes).parse
                @class_definition.var_types[exp[1]] ||= Set.new
                @class_definition.var_types[exp[1]].merge(types)
                @types.merge(types)
              end
              @class_definition.var_to_analyse.delete(exp[1])
            end
          end
          
          def process_lvar(exp)
            if(@var_types.has_key?(exp[1]))
              @types = @var_types[exp[1]]
            elsif(@var_to_analyse.has_key?(exp[1]))
              @types = Ruby::ProcessInferType.new(@var_to_analyse[exp[1]],@var_types, @var_to_analyse, @class_definition, @all_classes).parse
              @var_to_analyse.delete(exp[1])
              @var_types[exp[1]] ||= Set.new
              @var_types[exp[1]].merge(@types)
            end
          end

          def process_false(exp)
            @types = Set.new
            @types.add(false.class)
          end

          def process_lit(exp)
            @types = Set.new
            @types.add("Integer")
          end
          
          def process_array(exp)
            @types = Set.new
            @types.add("Array")
          end
          def process_hash(exp)
            @types = Set.new
            @types.add("Hash")
          end
          
          def process_str(exp)
            @types = Set.new
            @types.add("String")
          end
          
          #s(:return, s(:call, s(:call, s(:lvar, :b), :instance), :returnString))))
          def process_call(exp)
            _, caller, method_called = exp
            if(caller.nil?)
              @types = Set.new
              @types.add(@class_definition.class_name)
            else
              process(caller)
            end
            update_types(@types, method_called)
          end

        end
      end
    end
  end
end