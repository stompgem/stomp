#   Copyright 2005-2006 Brian McCallister
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
$:.unshift(File.dirname(__FILE__) + "/lib")
require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'
require "stomp/version"

begin
  require "hanna-nouveau"
  have_hanna = true
rescue LoadError => e
  have_hanna = false
end
require "rdoc/task"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "stomp"
    gem.version = Stomp::Version::STRING
    gem.summary = %Q{Ruby client for the Stomp messaging protocol}
    gem.license = "Apache-2.0"
    gem.description = %Q{Ruby client for the Stomp messaging protocol.  Note that this gem is no longer supported on rubyforge.}
    gem.email = ["brianm@apache.org", 'marius@stones.com', 'morellon@gmail.com',
       'allard.guy.m@gmail.com' ]
    gem.homepage = "https://github.com/stompgem/stomp"
    gem.authors = ["Brian McCallister", 'Marius Mathiesen', 'Thiago Morello',
        'Guy M. Allard']
    gem.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.1'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc 'Run the specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--colour']
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Rspec : run all with RCov"
RSpec::Core::RakeTask.new('spec:rcov') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rcov_opts = ['--exclude', 'gems', '--exclude', 'spec']
end

Rake::RDocTask.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_dir = "doc"
  rdoc.title = "Stomp"
  rdoc.options += %w[ --line-numbers --inline-source --charset utf-8 ]
  if have_hanna
    rdoc.options += %w[ --format hanna  ]
  end
  rdoc.rdoc_files.include("README.md", "CHANGELOG.md", "lib/**/*.rb")
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

task :default => :spec

