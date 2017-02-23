module Archruby
  module Ruby
    module TypeInference
      module Ruby

        class ProcessName < SexpInterpreter
          
          def initialize(ast)
            super()
            @ast = ast
            @complete_module_name = ""
          end

          def parse
            #binding.pry
            process(@ast)
            return @complete_module_name
          end
          
          def process_const(exp)
            _, const_name = exp
            @complete_module_name = const_name.to_s
          end
          
          def process_colon2(exp)
            _, values, const_name = exp
            process(values)
            @complete_module_name = "#{@complete_module_name}::#{const_name}"
          end
          
        end
      end
    end
  end
end