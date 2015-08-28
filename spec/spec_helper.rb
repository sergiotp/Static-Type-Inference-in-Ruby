files_path = File.expand_path('../../', __FILE__)
$LOAD_PATH.unshift(files_path) unless $LOAD_PATH.include?(files_path)
puts $LOAD_PATH.inspect

require 'ruby/parser'
require 'dependency_organizer'
require 'type_inference_checker'
