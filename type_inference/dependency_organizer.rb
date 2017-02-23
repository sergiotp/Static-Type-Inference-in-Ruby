module Archruby
  module Ruby
    module TypeInference

      class DependencyOrganizer
        attr_reader :dependencies, :class_definitions

        def initialize
          @dependencies = {}
          @class_definitions = {}
        end

        def add_dependencies(found_dependencies)
          found_dependencies.each do |class_dependency|
            class_name = class_dependency.name
            @dependencies[class_name] ||= Set.new
            @dependencies[class_name].merge(class_dependency.dependencies)
          end
        end

        
         def add_class_definitions(class_definitions)
=begin
          all_internal_method_calls = []
          class_definitions.each do |class_name, class_definition|
            class_definition.all_methods.each do |method_definition|
              internal_method_calls = []
              method_definition.method_calls.each do |internal_method_call|
                next if unused_internal_method_call?(internal_method_call)
                all_internal_method_calls << internal_method_call
                internal_method_calls << internal_method_call
              end
              method_definition.method_calls = internal_method_calls 
            end
          end
=end
          @class_definitions = class_definitions
          #add_args(all_internal_method_calls)
=begin
          class_definitions.each do |class_name, class_definition|
            class_definition.all_methods.each do |method_definition|
              #next if unused_method_definition?(method_definition)
              method_name = method_definition.method_name
              class_name = method_definition.class_name
              args = method_definition.args
              var_types = method_definition.var_types
              return_exp = method_definition.return_types
              internal_method_calls = []
              is_module = method_definition.is_module
              is_self = method_definition.is_self
              var_to_analyse = method_definition.var_to_analyse
              method_definition.method_calls.each do |internal_method_call|
                next if unused_internal_method_call?(internal_method_call)
                internal_method_calls << internal_method_call
                all_internal_method_calls << internal_method_call
              end
              #if !internal_method_calls.empty?
              method_def = Ruby::MethodDefinition.new(class_name, method_name, args, internal_method_calls, var_types, return_exp, is_module, is_self, var_to_analyse)
              @method_definitions[class_name] ||= []
              @method_definitions[class_name] << method_def
              #end
            end
          end
=end
        end
        
         def add_args(all_internal_method_calls)
          #percorre todos os internal_methods
          all_internal_method_calls.each do |internal_method|
          #descobre nome da classe que foi chamada
            class_name = internal_method.class_name.class == Array ? internal_method.class_name[0] : internal_method.class_name
            #percorre os métodos da classe
            if(@class_definitions.has_key?(class_name))
              @class_definitions[class_name].all_methods.each do |method_definition|
              #acha o método que foi chamado
                if(method_definition.method_name == internal_method.method_name)
                  for index in 0..(internal_method.new_params.size-1)
                    method_definition.add_arg(index, internal_method.new_params[index])
                  end
                end
              end
            end
          end
        end


        def read_from_csv_file
          require 'csv'
          new_dependencies = []
          CSV.foreach("information.csv") do |row|
            klass = row[0]
            klass.gsub!("#<Class:", "")
            klass.gsub!(">", "")
            method = row[1]
            size = row.size - 1
            class_dependency = Archruby::Ruby::TypeInference::Ruby::ClassDependency.new(klass)
            size.downto 0 do |pos|
              dependency = row[pos]
              dependency = dependency.split("|")
              if dependency.size > 1
                class_dep = dependency[1].strip
                if !class_dep.eql?("") && !Archruby::Ruby::CORE_LIBRARY_CLASSES.include?(class_dep)
                  class_dependency.add_dependency(class_dep)
                end
                break
              else
                class_dep = dependency[0].strip
                if !class_dep.eql?("") && !Archruby::Ruby::CORE_LIBRARY_CLASSES.include?(class_dep)
                  class_dependency.add_dependency(class_dep)
                end
              end
            end
            if class_dependency.dependencies.size > 0
              new_dependencies << class_dependency
            end
          end
          #binding.pry
          add_dependencies(new_dependencies)
        end

        def unused_method_definition?(method_definition)
          method_definition.method_calls.empty? || method_definition.class_name.to_s.empty?
        end

        def unused_internal_method_call?(internal_method_call)
          internal_method_call.params.nil?            ||
          internal_method_call.params.empty?          ||
          internal_method_call.class_name.to_s.empty?
        end
      end

    end
  end
end
