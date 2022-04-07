require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

get '/' do
  redirect '/search'
end

# AUTHENTICATION

get '/signup' do
end

post '/users' do
  redirect '/search'
end

get '/login' do
end

get '/users' do
  redirect '/search'
end

# SEARCH ALL PLANTS

# Render plant search form (no list)
get '/search' do
  erb :search
end

get '/plants' do
  # Temporary example data
  @plants = []
  erb :plants
end

# CUSTOM PLANTS

# Add plant to a user's custom plants
get '/users/plants/new' do
end

post '/users/plants' do
end

# Edit a custom plant
get '/users/plants/:id/edit' do
end

post '/users/plants/:id' do
end

# Inventories

# Manage inventories
get '/users/:username/inventories/new' do
end

post '/users/:username/inventories' do
end

# Render list of plants in user's inventory
get '/users/:username/inventories/:inventory_name' do
  erb :inventory
end

# Add a plant to a user's inventory
post '/users/:username/inventories/:inventory_name' do
end

# SETTINGS

get '/settings' do
  erb :settings
end