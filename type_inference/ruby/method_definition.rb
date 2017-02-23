module Archruby
  module Ruby
    module TypeInference
      module Ruby

        class MethodDefinition
          attr_reader :class_name, :method_name, :args, :method_calls, :var_types, :return_types, :is_module, :is_self, :var_to_analyse, :return_exps, :static_var_to_analyse
          attr_writer :method_calls, :is_self, :class_name
          
          def initialize(class_name, method_name, args, method_calls, var_types, return_exps, is_module, is_self, var_to_analyse, static_var_to_analyse)
            @class_name = class_name
            @method_name = method_name
            @args = args
            @method_calls = method_calls
            @var_types = var_types
            @return_exps = return_exps
            @is_module = "vai ser retirado"
            @is_self = is_self
            @var_to_analyse = var_to_analyse
            @static_var_to_analyse = static_var_to_analyse
            @return_types = Set.new
          end
          
          def copy_args_to_var_type
            @args.each do |var_name, set|
              if(!var_types.has_key? var_name)
                var_types[var_name] = Set.new
              end
              var_types[var_name].merge(set)
            end
          end
          
          def get_procs(var_name)
            procs = []
            if(@var_types.has_key?(var_name))
              @var_types[var_name].each do |type|
                if(type.include?("Proc#"))
                  procs << ProcStorage.instance.proc_definitions[type]
                end
              end
            end
            return procs
          end
          
          def add_arg(index, set)
            var_name = args.keys[index]
            args.values[index].merge(set)
            if(!var_types.has_key? var_name)
              var_types[var_name] = Set.new
            end
              var_types[var_name].merge(set)
          end
          
          def complete_name
            return "#{@class_name}::#{@method_name}"
          end
          
          def clone
            args_clone = {}
            args.each do |var_name, types|
              args_clone[var_name] = types.clone
            end
            var_types_clone = {}
            var_types.each do |var_name, types|
              var_types_clone[var_name] = types.clone
            end
            var_to_analyse_clone = {}
            var_to_analyse_clone.each do |var_name, exps|
              exps.each do |exp|
                var_to_analyse_clone[var_name] << exp.clone #verificar  
              end
            end
            return_exps_clone = []
            @return_exps.each do |exp|
              return_exps_clone << exp.clone
            end 
            return MethodDefinition.new(@class_name, @method_name, args_clone, @method_calls, var_types_clone, return_exps_clone, @is_module, @is_self, var_to_analyse_clone)            
          end

        end
      end
    end
  end
end
