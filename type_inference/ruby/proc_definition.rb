module Archruby
  module Ruby
    module TypeInference
      module Ruby
        
        class ProcDefinition
          
          attr_reader :var_types, :var_to_analyse, :static_var_types, :static_var_to_analyse, :id, :explicit_return_types, :explicit_return_exps, :implicit_return_types, :implicit_return_exps, :args, :clazz, :method
          attr_writer :var_types, :var_to_analyse, :static_var_types, :static_var_to_analyse, :id, :explicit_return_types, :explicit_return_exps, :implicit_return_types, :implicit_return_exps, :args, :clazz, :method
          
          def initialize()
            @@id ||= 0
            @id = @@id
            @@id += 1
            @var_types = {}
            @var_to_analyse = {}
            @static_var_types = {}
            @static_var_to_analyse = {}
            @explicit_return_types = Set.new
            @explicit_return_exps = []
            @implicit_return_types = Set.new
            @implicit_return_exps = []
            @args = {}
            @clazz = nil
            @method = nil
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
             
             
          def create_clone_to_process_call(params)
            var_types = {}
            @var_types.each do |var_name, types|
              var_types[var_name] = types.clone
            end
            var_to_analyse = {}
            @var_to_analyse.each do |var_name, exps|
              var_to_analyse[var_name] = []
              exps.each do |exp|
                var_to_analyse[var_name] << exp.clone
              end
            end
            static_var_types = {}
            @static_var_types.each do |var_name, types|
              static_var_types[var_name] = types.clone
            end
            static_var_to_analyse = {}
            @static_var_to_analyse.each do |var_name, exps|
              static_var_to_analyse[var_name] = []
              exps.each do |exp|
                static_var_to_analyse[var_name] << exp.clone
              end
            end
            explicit_return_exps = []
            @explicit_return_exps.each do |exp|
              explicit_return_exps << exp.clone
            end
            implicit_return_exps = []
            @implicit_return_exps.each do |exp|
              implicit_return_exps << exp.clone
            end
            args = {}
            @args.each do |var_name, types|
              args[var_name] = types.clone
              var_types[var_name] ||= Set.new
              var_types[var_name].merge(types)
            end
            var_args = @args.keys
            for i in 0..var_args.size - 1
              var_types[var_args[i]] ||= Set.new
              var_types[var_args[i]].add(params[i])
            end
            clone = ProcDefinition.new
            clone.var_types = var_types
            clone.var_to_analyse = var_to_analyse
            clone.static_var_types = static_var_types
            clone.static_var_to_analyse = static_var_to_analyse
            clone.explicit_return_exps = explicit_return_exps
            clone.implicit_return_exps = implicit_return_exps
            clone.args = args
            clone.clazz = @clazz
            clone.method = @method
            return clone
          end
          
        end
      end
    end
  end
end