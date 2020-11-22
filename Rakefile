require 'rake/clean'

CLEAN.include('data/fall-of-man')
CLOBBER.include('*.html')

desc 'Download posts'
task :download do
  require_relative 'download'
end

desc 'Compile an HTML pages'
task :compile do
  require_relative 'compile'
end

desc 'Download all posts and compile HTML pages'
task recompile: :clean do
  require_relative 'download'
  require_relative 'compile'
end

desc 'Run a server for HTML pages'
task :server do
  require_relative 'server'
  Sinatra::Application.run!
end

task default: :recompile
