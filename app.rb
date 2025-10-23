require 'sinatra'
require 'sinatra/reloader' if development?
require 'dotenv/load'
require 'redcarpet'
require 'sass-embedded'
require 'byebug' if development?
require_relative 'lib/outline_client'
require_relative 'models/document'

# Configure better_errors for development
if development?
  require 'better_errors'
  require 'binding_of_caller'

  use BetterErrors::Middleware
  # BetterErrors.application_root = __dir__
end

# Routes
get '/' do
  @document = Document.new(data: OutlineClient.new.get_collection, is_collection: true)
  @title = 'dxw’s Playbook'
  @status = :ok
  erb :document
end

get '/doc/:id' do
  @document = Document.new(id: params[:id])

  if @document.valid?
    @title = @document.title
    @status = :ok
  elsif @document.error?
    @title = 'Error'
    @status = :error
  else
    @title = 'Document Not Found'
    @status = :not_found
  end

  erb :document
end

get '/search' do
  @query = params[:query] || params[:q]
  if @query && !@query.empty?
    @results = OutlineClient.new.search_documents(@query).map { |res| Document.new(data: res['document']) }
    @title = 'Search results'
  else
    @title = 'Search'
  end
  erb :search
end

# Sass compilation route
get '/stylesheets/all.css' do
  content_type 'text/css', charset: 'utf-8'
  sass_file = File.read('assets/stylesheets/all.scss')
  Sass.compile_string(sass_file,
                      style: :compressed,
                      load_paths: ['assets/stylesheets', 'node_modules']).css
end

# Error handling
error do
  @title = 'Error'
  @error = env['sinatra.error']
  erb :error
end

# 404 handling
not_found do
  @title = 'Page not found'
  erb :not_found
end
