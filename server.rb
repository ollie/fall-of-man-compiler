require 'bundler'
Bundler.require(:default, :server)

require 'sinatra'

set :public_folder, __dir__

get '/' do
  send_file 'index.html'
end
