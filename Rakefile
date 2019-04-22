require 'rake/clean'

CLEAN.include('data')
CLOBBER.include('index.html')

desc 'Compile an index.html'
task :compile do
  require_relative 'compile'
end

desc 'Download all posts and compile new index.html'
task recompile: :clean do
  require_relative 'compile'
end

desc 'Run a server for index.html'
task :server do
  require_relative 'server'
  Sinatra::Application.run!
end
