# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'coffee-script'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "neighborparrot #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :assets_precompile do
  coffee_path = "coffee/src"
  out_path = "public/js"
  Dir.new(coffee_path).each do |file|
    if file.match '.coffee'
      coffee_file = "#{coffee_path}/#{file}"
      out_file = "#{out_path}/#{file.sub ".coffee", ".js"}"
      puts "Compile #{coffee_file} => #{out_file}"
      coffee = CoffeeScript.compile File.read(coffee_file)
      out = File.new(out_file, "w")
      out.write coffee
      out.close
    end
  end
end
