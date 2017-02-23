module Archruby
  module Ruby
    module TypeInference
      module Ruby

        class LocalScope
          attr_reader :var_types, :var_to_analyse, :static_var_to_analyse
          
          def initialize
            @var_types = {}
            @var_to_analyse = {}
            @static_var_to_analyse = {}
            @scopes = [Set.new]
            @formal_parameters = [Set.new]
            @current_scope = @scopes.last
            @current_formal_parameters = @formal_parameters.last
          end

          def add_var_type(name, type)
            if(!var_types.has_key?(name.to_sym) && name.to_sym != :self)
              @var_types[name.to_sym] = Set.new([type])
            elsif(name.to_sym != :self)
              @var_types[name.to_sym].add(type)
            end
          end
          
          def add_static_var_to_analyse(name, exp)
            @static_var_to_analyse[name.to_sym] ||= []
            @static_var_to_analyse[name.to_sym] << exp
          end
          
          def add_variable(name, type)
            add_var_type(name, type)
            @current_scope.add([name, type])
          end
          
          def add_var_to_analyse(name, exp)
            @var_to_analyse[name] = exp  
          end
          
          def add_formal_parameter(name, type)
            @current_formal_parameters.add([name, type])
          end

          def var_type(name)
            @current_scope.each do |var_info|
              if var_info[0].to_s == name.to_s
                return var_info[1]
              end
            end
            return nil
          end

          def has_formal_parameter(name)
            check_from_collection(@current_formal_parameters, name)
          end

          def has_local_params(name)
            check_from_collection(@current_scope, name)
          end

          def add_new_scope
            @scopes << Set.new
            @current_scope = @scopes.last
            @formal_parameters << Set.new
            @current_formal_parameters = @formal_parameters.last
          end

          def remove_scope
            @var_types = {}
            @var_to_analyse = {}
            @scopes.pop
            @current_scope = @scopes.last
            @formal_parameters.pop
            @current_formal_parameters = @formal_parameters.last
          end

          private

          def check_from_collection(collection, name)
            collection.each do |var_info|
              if var_info[0].to_s == name.to_s
                return true
              end
            end
            return false
          end
        end

      end
    end
  end
end
