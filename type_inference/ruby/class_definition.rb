module Archruby
  module Ruby
    module TypeInference
      module Ruby
        
        class ClassDefinition
          
          attr_reader :class_name, :complete_class_name, :var_types, :var_to_analyse, :static_var_types, :static_var_to_analyse, :methods
          
          def initialize(class_name, complete_class_name)
            @class_name = class_name
            @complete_class_name = complete_class_name
            @var_types = {}
            @var_to_analyse = {}
            @static_var_types = {}
            @static_var_to_analyse = {}
            @methods = []
            @methods_self = []
          end
         
         
          def clear_methods
            @methods = []
            @methods_self = []
          end
          def all_methods
             return @methods + @methods_self
          end
         
          def add_method_self(method_definition)
            @methods_self << method_definition
          end
          
          def add_method(method_definition)
            @methods << method_definition
          end
          
          def has_method?(method_name, is_self = nil)
            @methods.each do |method|
              if(method_name == method.method_name)
                if(is_self.nil? || (is_self && method.is_self) || (!is_self && !method.is_self))
                  return true
                end
              end
            end
            return false
          end
          
          def add_var(var_name, type)
            if(!@var_types.has_key?(var_name))
              @var_types[var_name] = Set.new
            end
            @var_types[var_name].add(type)
          end
          
          def add_var_to_analyse(var_name, exp)
            if(!@var_to_analyse.has_key?(var_name))
              @var_to_analyse[var_name] = []
            end
            @var_to_analyse[var_name] << exp
          end
          
          
          def add_static_var(var_name, type)
            if(!@static_var_types.has_key?(var_name))
              @static_var_types[var_name] = Set.new
            end
            @static_var_types[var_name].add(type)
          end
          
          def add_static_var_to_analyse(var_name, exp)
            if(!@static_var_to_analyse.has_key?(var_name))
              @static_var_to_analyse[var_name] = []
            end
            @static_var_to_analyse[var_name] << exp
          end
          
          def merge(class_definition, is_extend)
            
            #merge var_type
            class_definition.var_types.each do |var_name, types|
              var_types = (is_extend) ? @static_var_types : @var_types
              if(!var_types.has_key?(var_name))
                var_types[var_name] = Set.new
              end
              var_types[var_name] = types.clone
            end
            
            #merge var_to_analyse
            class_definition.var_to_analyse.each do |var_name, exps|
              var_to_analyse = (is_extend) ? @static_var_to_analyse : @var_to_analyse
              if(!var_to_analyse.has_key?(var_name))
                var_to_analyse[var_name] = []
              end
              var_to_analyse[var_name] = exps.clone #trocar depois
            end
            
            #merge methods
            class_definition.methods.each do |method_definition|
              clone = method_definition.clone
              clone.is_self = is_extend
              clone.class_name = @class_name
              @methods << clone
            end  
          end
          
        end
      end
    end
  end
end