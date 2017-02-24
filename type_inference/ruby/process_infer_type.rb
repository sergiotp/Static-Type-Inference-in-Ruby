module Archruby
  module Ruby
    module TypeInference
      module Ruby
        class ProcessInferType < SexpInterpreter
          
          
          def self.infer_all(all_classes)
            all_classes.each do |class_name, class_definition|
              class_definition.all_methods.each do |method|
                Ruby::ProcessInferType.infer_var_method(method, class_definition, all_classes)
                Ruby::ProcessInferType.infer_return_method(method, class_definition, all_classes)
              end
            end  
          end
          
          def self.infer_return_method(method, clazz, all_classes)
            while(method.return_exps.size > 0)
              exp = method.return_exps.pop
              return_types = Ruby::ProcessInferType.new(exp, method.var_types, method.var_to_analyse, method.static_var_to_analyse, clazz, all_classes).parse
              method.return_types.merge(return_types)
            end
          end
          
          def self.infer_var_method(method, clazz, all_classes)
            method.static_var_to_analyse.each do |var_name, exps|
              while(exps.size > 0)
                exp = exps.pop
                types = Ruby::ProcessInferType.new(exp, method.var_types, method.var_to_analyse, method.static_var_to_analyse, clazz, all_classes).parse
                if(method.is_self)
                  clazz.static_var_types[var_name] ||= Set.new
                  clazz.static_var_types[var_name].merge(types)
                else
                  clazz.var_types[var_name] ||= Set.new
                  clazz.var_types[var_name].merge(types)
                end
              end
              method.static_var_to_analyse.delete(var_name)
            end
            
            method.var_to_analyse.each do |var_name, exp|
              return_types = Ruby::ProcessInferType.new(exp, method.var_types, method.var_to_analyse, method.static_var_to_analyse, clazz, all_classes).parse
              method.var_types[var_name] ||= Set.new
              method.var_types[var_name].merge(return_types)
              method.var_to_analyse.delete(var_name)  
            end
          end
          
          def self.infer_proc_calls(proc, params, method, all_classes, var_assigned)
            proc_called = proc.create_clone_to_process_call(params)
            while(proc_called.explicit_return_exps.size > 0)
              exp = proc_called.explicit_return_exps.pop
              types = Ruby::ProcessInferType.new(exp, proc_called.var_types, proc_called.var_to_analyse, proc_called.static_var_to_analyse, proc_called.clazz, all_classes).parse
              method.var_types[var_assigned] ||= Set.new
              method.var_types[var_assigned].merge(types)
            end
            
            proc_called.static_var_to_analyse.each do |var_name, exps|
              while(exps.size > 0)
                exp = exps.pop
                types = Ruby::ProcessInferType.new(exp, proc_called.var_types, proc_called.var_to_analyse, proc_called.static_var_to_analyse, proc_called.clazz, all_classes).parse
                proc_called.clazz.var_types[var_name] ||= Set.new  
                proc_called.clazz.var_types[var_name].merge(types)
              end
            end
            
            proc_called.var_to_analyse.each do |var_name, exps|
              while(exps.size > 0)
                exp = exps.pop
                types = Ruby::ProcessInferType.new(exp, proc_called.var_types, proc_called.var_to_analyse, proc_called.static_var_to_analyse,proc_called.clazz, all_classes).parse
                proc_called.var_types[var_name] ||= Set.new  
                proc_called.var_types[var_name].merge(types)
              end
            end
            
          end
          
          def initialize(exp, var_types, var_to_analyse, static_var_to_analyse, class_definition, all_classes)
            super()
            self.strict = false
            self.default_method = "process_nothing"
            @var_types = var_types
            @var_to_analyse = var_to_analyse
            @static_var_to_analyse = static_var_to_analyse
            @class_definition = class_definition
            @all_classes = all_classes
            @ast = exp
            @types = Set.new            
          end
          
          def parse
            process(@ast)
            @types
          end
          
          def process_nothing(exp)
            
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
            if(@static_var_to_analyse.has_key?(exp[1]))
              while(@static_var_to_analyse[exp[1]].size > 0)
                exp_to_analyse = @static_var_to_analyse[exp[1]].pop
                types = Ruby::ProcessInferType.new(exp, @var_types, @var_to_analyse, @static_var_to_analyse, @class_definition, @all_classes).parse
                @class_definition.var_types[exp[1]] ||= Set.new
                @class_definition.var_types[exp[1]].merge(types)
                @types.merge(types)
              end
            end
          end
          
          def process_lvar(exp)
            @types = Set.new
            if(@var_types.has_key?(exp[1]))
              @types = @var_types[exp[1]]
            elsif(@var_to_analyse.has_key?(exp[1]))
              @types = Ruby::ProcessInferType.new(@var_to_analyse[exp[1]],@var_types, @var_to_analyse, @static_var_to_analyse, @class_definition, @all_classes).parse
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