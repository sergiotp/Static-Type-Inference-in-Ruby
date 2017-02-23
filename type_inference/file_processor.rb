require 'sexp_processor'
require 'ruby_parser'
require 'pry'
require_relative 'ruby/class_dependency.rb'
require_relative 'ruby/internal_method_invocation.rb'
require_relative 'ruby/local_scope.rb'
require_relative 'ruby/method_definition.rb'
require_relative 'ruby/class_definition.rb'
require_relative 'ruby/proc_definition.rb'
require_relative 'ruby/proc_storage.rb'
require_relative 'ruby/parser_for_typeinference.rb'
require_relative 'ruby/process_method_arguments.rb'
require_relative 'ruby/process_method_body.rb'
require_relative 'ruby/process_method_params.rb'
require_relative 'ruby/process_method_return.rb'
require_relative 'ruby/process_infer_type.rb'
require_relative 'ruby/process_include.rb'
require_relative 'dependency_organizer.rb'
require_relative 'type_inference_checker.rb'
 
file_content = File.open("/home/elder/Documents/Aptana Studio 3 Workspace/archruby/lib/archruby/ruby/type_inference/target.rb", "rb").read
puts "AST: #{RubyParser.new.parse(file_content).to_s}"

puts "#{"="*35} Comments #{"="*35}"
parser = Archruby::Ruby::TypeInference::Ruby::ParserForTypeinference.new
dependencies, class_definitions = parser.parse(file_content)

dependency_organizer = Archruby::Ruby::TypeInference::DependencyOrganizer.new
dependency_organizer.add_dependencies(dependencies)
dependency_organizer.add_class_definitions(class_definitions)

verify_type = Archruby::Ruby::TypeInference::TypeInferenceChecker.new(
  dependency_organizer.dependencies,
  dependency_organizer.class_definitions
)

new_deps = verify_type.dependencies
new_methods = verify_type.class_definitions


verify_type.add_dependency_based_on_calls
verify_type.add_dependency_based_on_internal_calls
verify_type.check_returns
verify_type.check_proc_calls

class_definitions = verify_type.class_definitions
procs = Archruby::Ruby::TypeInference::Ruby::ProcStorage.instance.proc_definitions

#Archruby::Ruby::TypeInference::Ruby::ProcessMethodReturn.check(class_definitions)
puts "#{"="*80}"

binding.pry