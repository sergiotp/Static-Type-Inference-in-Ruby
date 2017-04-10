module Archruby
  module Ruby
    module TypeInference
      module Ruby

        class ProcessMethodBody < SexpInterpreter
          def initialize(method_name, ast, local_scope, class_defined_methods = nil, class_definition, is_self)
            super()
            @ast = ast
            @params = {}
            @current_dependency_class = []
            @current_dependency_class_name = nil
            @method_calls = []
            @local_scope = local_scope
            @method_name = method_name
            @class_defined_methods = class_defined_methods
            @class_definition = class_definition
            @return_exp = []
            @last_exp = []
            @is_self = is_self
            @is_proc = false # controle para verificar se está processando um bloco
            @current_variable = nil            
            @procs_declared = []
          end

          def get_last_stm(exp)
            #caso especial
            if(exp[0] == :case)
              return exp
            end
            last_stm = exp
            if(exp.respond_to?:each_sexp)
              exp.each_sexp do |stm|
                last_stm = stm
              end
            else
              exp.each do |stm|
                if(stm.class == Sexp)
                  last_stm = stm
                end
              end
            end
            return last_stm
          end
          
          def check_implicit_return_if(exp)
            _, condition, true_body, else_body = exp
            implicit_returns = []
            if(!true_body.nil?)
              last_stm = get_last_stm(true_body)
              implicit_returns.concat(check_implicit_return(last_stm))
            end
            if(!else_body.nil?)
              last_stm = get_last_stm(else_body)
              implicit_returns.concat(check_implicit_return(last_stm))
            end
            return implicit_returns
          end
          
          def check_implicit_return_case(exp)
            _, _, *whens = exp  
            implicit_returns = []
            whens.each do |when_exp|
              if(!when_exp.nil?)
                last_stm = get_last_stm(when_exp)
                implicit_returns.concat(check_implicit_return(last_stm))
              end
            end
            return implicit_returns
          end
          
          def check_implicit_return(exp)
            if(!exp.nil?)
              if(exp[0] == :if)
                return check_implicit_return_if(exp)
              elsif(exp[0] == :case)
                return check_implicit_return_case(exp)
              else
                return [exp]
              end
            else
              return []
            end
          end

          def parse
            @ast.map {|sub_tree| process(sub_tree)}
            @return_exp.concat(check_implicit_return(get_last_stm(@ast)))
            return @method_calls, @local_scope.var_types, @local_scope.var_to_analyse, @local_scope.static_var_to_analyse, @return_exp, @procs_declared
          end

          def process_call(exp)
            _, receiver, method_name, *params = exp
            if receiver && receiver[0] == :lvar && receiver[1].class == Symbol
              type = @local_scope.var_type(receiver[1])
              parsed_params, new_params = ProcessMethodParams.new(params, @local_scope).parse
              add_method_call(type, method_name, parsed_params, exp.line, receiver[1], new_params)
            elsif receiver && receiver[0] == :self
              type = @local_scope.var_type("self").dup
              parsed_params, new_params = ProcessMethodParams.new(params, @local_scope).parse
              add_method_call(type, method_name, parsed_params, exp.line, "self", new_params)
            elsif !receiver.nil?
              process(receiver)
              parsed_params = nil
              if check_if_has_params(params)
                parsed_params, new_params = ProcessMethodParams.new(params, @local_scope).parse
              end
              add_method_call(@current_dependency_class_name, method_name, parsed_params, exp.line, nil, new_params)
              #@current_dependency_class_name = nil
            else
              if @class_defined_methods && @class_defined_methods.include?(method_name)
                type = @local_scope.var_type("self").dup
                if check_if_has_params(params)
                  parsed_params, new_params = ProcessMethodParams.new(params, @local_scope).parse
                end
                add_method_call(type, method_name, parsed_params, exp.line, "self", new_params)
              end
            end
          end

          def process_defs(exp)
            #estudar esse caso -> acontece no rails em activemodel
          end

          def check_if_has_params(params)
            has_local_params = false
            params.each do |param|
              if param[0] == :lvar
                has_local_params = @local_scope.has_formal_parameter(param[1]) || @local_scope.has_local_params(param[1])
              end
            end
            has_local_params
          end

          def add_method_call(class_name, method_name, params=nil, line_num=nil, var_name=nil, new_params = nil)
            @method_calls << InternalMethodInvocation.new(class_name, method_name, params, line_num, var_name, new_params, @current_variable)
          end

          def process_lasgn(exp)
            _, variable_name, *args = exp
            @current_variable = variable_name
            @current_dependency_class_name = nil
            args.map { |subtree| process(subtree) }
            #puts "#{@local_scope.var_type("self").first}, #{@method_name}, #{variable_name} | #{@current_dependency_class_name}"
            if @current_dependency_class_name
              if(@is_proc)
                ProcStorage.instance.last_added_proc.add_var(variable_name, @current_dependency_class_name)
                puts "var #{variable_name} (type #{@current_dependency_class_name}) added in  the scope of proc##{ProcStorage.instance.last_added_proc.id} "
              else
                @local_scope.add_variable(variable_name, @current_dependency_class_name)
                if ["String", "Integer", "Array", "Hash"].include?(@current_dependency_class_name)
                  add_method_call(@current_dependency_class_name , nil, nil, exp.line, variable_name, nil)
                end
                puts "var #{variable_name} (type #{@current_dependency_class_name}) added in  the scope of #{@method_name} method"
              end
            else
              if(@is_proc)
                ProcStorage.instance.last_added_proc.add_var_to_analyse(variable_name, exp[2])
                puts "var to analyse #{variable_name} (exp: #{exp[2].to_s}) added in  the scope of proc##{ProcStorage.instance.last_added_proc.id}"
              else
                @local_scope.add_var_to_analyse(variable_name, exp[2])
                puts "var to analyse #{variable_name} (exp: #{exp[2].to_s}) added in  the scope of #{@method_name} method"
              end
            end
            @current_dependency_class_name = nil
            @current_variable = nil
          end

          def process_const(exp)
            _, const_name = exp
            if !@current_dependency_class.empty?
              @current_dependency_class_name = build_full_name(const_name)
            else
              @current_dependency_class_name = const_name.to_s
            end
          end

          def process_colon3(exp)
            _, constant_name = exp
            @current_dependency_class_name = build_full_name("::#{constant_name}")
          end

          def process_colon2(exp)
            _, first_part, last_part = exp
            @current_dependency_class.unshift(last_part)
            process(first_part)
          end

          def build_full_name(const_name)
            @current_dependency_class.unshift(const_name)
            full_class_path = @current_dependency_class.join('::')
            @current_dependency_class = []
            full_class_path
          end

          def process_attrasgn(exp)
            _, receiver, method_name, value = exp
            process(receiver)
            process(value)
          end

          def process_iasgn(exp)
            _, instance_variable_name, *value = exp
            @current_variable = instance_variable_name
            value.map { |subtree| process(subtree) }
            if(@is_proc && @current_dependency_class_name)
              ProcStorage.instance.last_added_proc.add_static_var(instance_variable_name, @current_dependency_class_name)
              puts "static var #{instance_variable_name} (type: #{@current_dependency_class_name}) added in proc##{ProcStorage.instance.last_added_proc.id}"
            elsif @is_proc
              ProcStorage.instance.last_added_proc.add_static_var_to_analyse(instance_variable_name, exp[2])
              puts "static var #{instance_variable_name} (type: #{exp[2].to_s}) added in proc##{ProcStorage.instance.last_added_proc.id}"
            elsif @is_self && @current_dependency_class_name
              puts "static var #{instance_variable_name} (type: #{@current_dependency_class_name}) added in #{@class_definition.class_name} class"
              @class_definition.add_static_var(instance_variable_name, @current_dependency_class_name)
              if ["String", "Integer", "Array", "Hash"].include?(@current_dependency_class_name)
                add_method_call(@current_dependency_class_name , nil, nil, exp.line, instance_variable_name, nil)
              end
            elsif @is_self
              puts "static var to analyse #{instance_variable_name} (exp: #{exp[2].to_s}) added in #{@class_definition.class_name} class"
              @local_scope.add_static_var_to_analyse(instance_variable_name, exp[2])
              #@class_definition.add_static_var_to_analyse(instance_variable_name, exp[2])
            elsif !@is_self && @current_dependency_class_name
              puts "global var #{instance_variable_name} (type: #{@current_dependency_class_name}) added in #{@class_definition.class_name} class"
              @class_definition.add_var(instance_variable_name, @current_dependency_class_name)
              if ["String", "Integer", "Array", "Hash"].include?(@current_dependency_class_name)
                add_method_call(@current_dependency_class_name , nil, nil, exp.line, instance_variable_name, nil)
              end
            elsif !@is_self
              puts "global var to analyse #{instance_variable_name} (exp: #{exp[2].to_s}) added in #{@class_definition.class_name} class"
              @local_scope.add_static_var_to_analyse(instance_variable_name, exp[2])
              #@class_definition.add_var_to_analyse(instance_variable_name, exp[2])
            end
            @current_dependency_class_name = nil
            @current_variable = nil
          end

          def process_op_asgn1(exp)
            process(exp.last)
          end

          def process_match3(exp)
            _, left_side, right_side = exp
            process(left_side)
            process(right_side)
          end

          def process_op_asgn2(exp)
            _, receiver, method, met, last = exp
            process(receiver)
            process(last)
          end


          def add_var_types_in_proc(proc)
            @local_scope.var_types.each do |var_name, types|
              proc.var_types[var_name] = types.clone
            end
            @local_scope.var_to_analyse.each do |var_name, exps|
              proc.var_to_analyse[var_name] = []
              exps.each do |exp|
                proc.var_to_analyse[var_name] << exp.clone
              end
            end
          end
          
          def process_iter(exp)
            _, first_part, second_part, body = exp
            process(first_part)
            if(@current_dependency_class_name == "Proc")
              @current_dependency_class_name = nil
              @is_proc = true
              ProcStorage.instance.add_proc(ProcDefinition.new)
              @procs_declared << ProcStorage.instance.last_added_proc
              add_var_types_in_proc(ProcStorage.instance.last_added_proc)
              if(second_part != 0)
                process(second_part)
              end
              #body.map {|sub_tree| process(sub_tree)}
              process(body)
              @current_dependency_class_name = "Proc##{ProcStorage.instance.last_added_proc.id}"
              ProcStorage.instance.last_added_proc.explicit_return_exps.concat(check_implicit_return(get_last_stm(body)))
              @is_proc = false
            else
              #body.map! {|sub_tree| process(sub_tree)}
              process(body)
            end
          end

          def process_args(exp)
            if(@is_proc)
              ProcStorage.instance.last_added_proc.args = ProcessMethodArguments.new(exp).parse
            end
          end
          
          def process_if(exp)
            _, condition, true_body, else_body = exp
            process(condition)
            process(true_body)
            process(else_body)
          end

          def process_dsym(exp)
            _, str, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_block(exp)
            _, *args = exp
            args.map! { |subtree| process(subtree) }
          end

          def process_hash(exp)
            _, key, value = exp
            process(key)
            process(value)
            @current_dependency_class_name = "Hash"
          end

          def process_super(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_rescue(exp)
            _, normal, *rescue_body = exp
            process(normal)
            rescue_body.map! {|sub_tree| process(sub_tree)}
          end

          def process_return(exp)
            _, value = exp
            if(@is_proc)
              ProcStorage.instance.last_added_proc.explicit_return_exps << value
            else
              @return_exp << value
            end
            
            #value.map! {|sub_tree| process(sub_tree)}
          end

          def process_resbody(exp)
            _, class_to_rescue, *body = exp
            process(class_to_rescue)
            body.map! {|sub_tree| process(sub_tree)}
          end

          
          
          def process_array(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
            @current_dependency_class_name = "Array"
          end

          def process_and(exp)
            _, left_side, right_side = exp
            process(left_side)
            process(right_side)
          end

          def process_or(exp)
            _, left_side, right_side = exp
            process(left_side)
            process(right_side)
          end

          def process_dstr(exp)
            _, start, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_dregx_once(exp)
            _, start, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_evstr(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_dstr(exp)
            _, init, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_dxstr(exp)
            _, str, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_ivar(exp)
            _, var_name, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_match2(exp)
            _, rec, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_match3(exp)
            _, first, second = exp
            process(first)
            process(second)
          end

          def process_svalue(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_op_asgn_or(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_op_asgn_and(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_ensure(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_while(exp)
            _, condition, body = exp
            process(condition)
            process(body)
          end

          def process_until(exp)
            _, condition, body, *args = exp
            process(condition)
            process(body)
          end

          def process_yield(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_splat(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_case(exp)
            _, condition, when_part, ensure_part = exp
            process(condition)
            process(when_part)
            process(ensure_part)
          end

          def process_for(exp)
            _, x, y, body = exp
            process(x)
            process(y)
            process(body)
          end

          def process_when(exp)
            _, condition, body = exp
            process(condition)
            process(body)
          end

          def process_rescue(exp)
            _, body, rescbody = exp
            process(body)
            process(rescbody)
          end

          def process_cvasgn(exp)
            _, class_var_name, *value = exp
            value.map! {|sub_tree| process(sub_tree)}
          end

          def process_dot3(exp)
            _, left, right = exp
            process(left)
            process(right)
          end

          def process_dot2(exp)
            _, left, right = exp
            process(left)
            process(right)
          end

          def process_block_pass(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_retry(exp)
          end

          def process_dregx(exp)
            _, str, *args = exp
            args.map! {|sub_tree| process(sub_tree) if sub_tree.class == Sexp}
          end

          def process_defn(exp)
            #estudar esse caso para ver se vamos quer pegar isso
          end

          def process_masgn(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_redo(exp)
          end

          def process_to_ary(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_gasgn(exp)
            _, global_var_name, *value = exp
            value.map! {|sub_tree| process(sub_tree)}
          end

          def process_sclass(exp)
            _, singleton_class, *body = exp
            body.map! {|sub_tree| process(sub_tree)}
          end

          def process_not(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_defined(exp)
            _, *args = exp
            args.map! {|sub_tree| process(sub_tree)}
          end

          def process_cvdecl(exp)
            _, instance_classvar_name, *value = exp
            value.map! {|sub_tree| process(sub_tree)}
          end

          def process_back_ref(exp)
          end

          def process_cvar(exp)
            # class variable
          end

          def process_alias(exp)
          end

          def process_begin(exp)
          end

          def process_self(exp)
          end

          def process_xstr(exp)
          end

          def process_nth_ref(exp)
          end

          def process_break(exp)
          end

          def process_next(exp)
            _, value = exp
            if(@is_proc)
              ProcStorage.instance.last_added_proc.explicit_return_exps << value
            end
          end

          def process_str(exp)
            @current_dependency_class_name = "String"
          end

          def process_gvar(exp)
          end

          def process_nil(exp)
          end

          def process_zsuper(exp)
          end

          def process_lit(exp)
            @current_dependency_class_name = "#{exp[1].class}"
          end

          def process_lvar(exp)
          end

          def process_true(exp)
          end

          def process_false(exp)
          end

        end

      end
    end
  end
end
