module Archruby
  module Ruby
    module TypeInference
      module Ruby
        class ProcessMethodReturn < SexpInterpreter
          
          def self.check(class_definitions)
            class_definitions.each do |class_name, class_definition|
              class_definition.all_methods.each do |method|
                self.analyse_return_method(method, class_definition, class_definitions)
                puts "Tipos de retorno de #{method.complete_name}: #{method.return_types.to_a}"
              end
            end
          end

          def self.analyse_return_method(method, class_definition, class_definitions)
             while(method.return_exps.size > 0)
              exp = method.return_exps.pop
              returns = Ruby::ProcessMethodReturn.new(method, exp, class_definition, class_definitions).parse
              method.return_types.merge(returns)
            end
          end
          
          def initialize(method, ast, class_definition, class_definitions)
            super()
            @method = method
            @ast = ast
            @class_definition = class_definition
            @class_definitions = class_definitions            
            @types = Set.new
            
          end

          def parse
            process(@ast)
            @types
          end

          def update_types(types_set, method_called)
            @types = Set.new
            types_set.each do |class_name|
              if(@class_definitions.has_key?(class_name))
                @class_definitions[class_name].all_methods.each do |method|
                  if(method.method_name == method_called)
                    Archruby::Ruby::TypeInference::Ruby::ProcessMethodReturn.analyse_return_method(method, @class_definitions[class_name], @class_definitions)
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
                types = Ruby::ProcessMethodReturn.new(@method, exp_to_analyse,@class_definition, @class_definitions).parse
                @class_definition.var_types[exp[1]] ||= Set.new
                @class_definition.var_types[exp[1]].merge(types)
                @types.merge(types)
              end
              @class_definition.var_to_analyse.delete(exp[1])
            end
          end
          
          def process_lvar(exp)
            if(@method.var_types.has_key?(exp[1]))
              @types = @method.var_types[exp[1]]
            elsif(@method.var_to_analyse.has_key?(exp[1]))
              @types = Ruby::ProcessMethodReturn.new(@method, @method.var_to_analyse[exp[1]],@class_definition, @class_definitions).parse
              @method.var_to_analyse.delete(exp[1])
              @method.var_types[exp[1]] ||= Set.new
              @method.var_types[exp[1]].merge(@types)
            end
          end

          def process_false(exp)
            @types = Set.new
            @types.add(false.class)
          end

          def process_lit(exp)
            @types = Set.new
            puts "test"
            puts "#{exp[1]} e #{exp[1].class}"
            @types.add("Integer")
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
              @types.add(@method.class_name)
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