files_path = File.expand_path('../', __FILE__)
$LOAD_PATH.unshift(files_path) unless $LOAD_PATH.include?(files_path)

require 'ruby/parser'
require 'dependency_organizer'
require 'type_inference_checker'
require 'pry'

projects = []

homebrew = { name: 'homebrew', files: "/Users/sergiomiranda/Sources/homebrew/Library/**/*.rb" }
projects << homebrew

rails = { name: 'rails', files: [
  "/Users/sergiomiranda/Sources/rails/actionmailer/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/actionpack/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/actionview/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/activejob/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/activemodel/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/activerecord/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/activesupport/lib/**/*.rb",
  "/Users/sergiomiranda/Sources/rails/railties/lib/**/*.rb"
]}
projects << rails

jekkyl = {name: 'jekkyl', files: "/Users/sergiomiranda/Sources/jekyll/lib/**/*.rb" }
projects << jekkyl

gitlab = {name: 'gitlab', files: [
  "/Users/sergiomiranda/Sources/gitlabhq/app/**/*.rb",
  "/Users/sergiomiranda/Sources/gitlabhq/config/**/*.rb",
  "/Users/sergiomiranda/Sources/gitlabhq/lib/**/*.rb"
]}
projects << gitlab

discourse = {name: 'discourse', files: [
  "/Users/sergiomiranda/Sources/discourse/app/**/*.rb",
  "/Users/sergiomiranda/Sources/discourse/config/**/*.rb",
  "/Users/sergiomiranda/Sources/discourse/lib/**/*.rb"
]}
projects << discourse

devise = { name: 'devise', files: "/Users/sergiomiranda/Sources/devise/lib/**/*.rb" }
projects << devise

diaspora = { name: 'diaspora', files: [
  "/Users/sergiomiranda/Sources/diaspora/app/**/*.rb",
  "/Users/sergiomiranda/Sources/diaspora/config/**/*.rb",
  "/Users/sergiomiranda/Sources/diaspora/lib/**/*.rb"
]}
projects << diaspora

huginn = {name: 'huginn', files: [
  "/Users/sergiomiranda/Sources/huginn/app/**/*.rb",
  "/Users/sergiomiranda/Sources/huginn/config/**/*.rb",
  "/Users/sergiomiranda/Sources/huginn/lib/**/*.rb"
]}
projects << huginn

vagrant = { name: 'vagrant', files: "/Users/sergiomiranda/Sources/vagrant/lib/**/*.rb" }
projects << vagrant

bootstrap_sass = { name: 'bootstrap_sass', files: "/Users/sergiomiranda/Sources/bootstrap-sass/lib/**/*.rb" }
projects << bootstrap_sass

octopress = { name: 'octopress', files: "/Users/sergiomiranda/Sources/octopress/plugins/**/*.rb" }
projects << octopress

ruby = { name: 'ruby', files: "/Users/sergiomiranda/Sources/ruby/lib/**/*.rb" }
projects << ruby

capistrano = { name: 'capistrano', files: "/Users/sergiomiranda/Sources/capistrano/lib/**/*.rb"}
projects << capistrano

homebrew_cask = { name: 'homebrew_cask', files: "/Users/sergiomiranda/Sources/homebrew-cask/lib/**/*.rb"}
projects << homebrew_cask

paperclip = { name: 'paperclip', files: "/Users/sergiomiranda/Sources/paperclip/lib/**/*.rb" }
projects << paperclip

resque = { name: 'resque', files: "/Users/sergiomiranda/Sources/resque/lib/**/*.rb" }
projects << resque

spree = { name: 'spree', files: [
    "/Users/sergiomiranda/Sources/spree/api/**/*.rb",
    "/Users/sergiomiranda/Sources/spree/backend/**/*.rb",
    "/Users/sergiomiranda/Sources/spree/core/**/*.rb"
]}
projects << spree

grape = { name: 'grape', files: "/Users/sergiomiranda/Sources/grape/lib/**/*.rb" }
projects << grape

sass = { name: 'sass', files: "/Users/sergiomiranda/Sources/sass/lib/**/*.rb" }
projects << sass

capybara = { name: 'capybara', files: "/Users/sergiomiranda/Sources/capybara/lib/**/*.rb" }
projects << capybara

cocoapods = { name: 'cocoapods', files: "/Users/sergiomiranda/Sources/CocoaPods/lib/**/*.rb" }
projects << cocoapods

activeadmin = { name: 'activeadmin', files: "/Users/sergiomiranda/Sources/activeadmin/lib/**/*.rb" }
projects << activeadmin

carrierwave = { name: 'carrierwave', files: "/Users/sergiomiranda/Sources/carrierwave/lib/**/*.rb" }
projects << carrierwave

devdocs = { name: 'devdocs', files: "/Users/sergiomiranda/Sources/devdocs/lib/**/*.rb" }
projects << devdocs

cancan = { name: 'cancan', files: "/Users/sergiomiranda/Sources/cancan/lib/**/*.rb" }
projects << cancan

whenever = { name: 'whenever', files: "/Users/sergiomiranda/Sources/whenever/lib/**/*.rb" }
projects << whenever

fpm = { name: 'fpm', files: "/Users/sergiomiranda/Sources/fpm/lib/**/*.rb" }
projects << fpm

rails_admin = { name: 'rails_admin', files: "/Users/sergiomiranda/Sources/rails_admin/lib/**/*.rb" }
projects << rails_admin

simple_form = { name: 'simple_form', files: "/Users/sergiomiranda/Sources/simple_form/lib/**/*.rb" }
projects << simple_form

projects.each do |project|
  project_name = project[:name]
  project_files = project[:files]
  puts "Starting to analyze: #{project_name}"
  dirs = Dir.glob(project_files)
  count = 1
  start_time = Time.now
  dependency_organizer = DependencyOrganizer.new
  dirs.each do |file_path|
    next if file_path.include?("template")
    next if file_path.include?("adapter_specific_registry")
    file = File.open(file_path)
    count += 1
    # puts "Total processado: #{count}"
    # puts "Total: #{dirs.size}"
    # puts file_path
    file_content = file.read
    file.close
    parser = Parser.new
    dependencies, methods_calls = parser.parse(file_content)
    dependency_organizer.add_dependencies(dependencies)
    dependency_organizer.add_method_calls(methods_calls)
  end
  verify_type = TypeInferenceChecker.new(dependency_organizer.dependencies,
                                dependency_organizer.method_definitions
                                )
  total_deps_without_heuristics = verify_type.total_deps
  verify_type.add_dependency_based_on_calls
  verify_type.add_dependency_based_on_internal_calls
  total_deps_with_heuristics = verify_type.total_deps
  end_time = Time.now
  seconds_diff = (start_time - end_time).to_i.abs
  puts "++++++++++++++++++++++++++++++++++++++"
  puts "Project: #{project_name}"
  puts "Total Deps Without Heuristics: #{total_deps_without_heuristics}"
  puts "Total Deps With Heuristics: #{total_deps_with_heuristics}"
  puts "Processing Time(s): #{seconds_diff}"
  puts "++++++++++++++++++++++++++++++++++++++\n\n"
end
