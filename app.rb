require 'sinatra'
require 'sinatra/reloader' if development?
require 'dotenv/load'
require 'kramdown'
require 'sass-embedded'
require 'byebug' if development?
require 'rollbar'
require_relative 'lib/outline_client'
require_relative 'lib/url_mapper'
require_relative 'models/document'
require_relative 'models/search_result'

# Configure Rollbar for error monitoring
Rollbar.configure do |config|
  config.access_token = ENV.fetch('ROLLBAR_ACCESS_TOKEN', nil)
  config.environment = ENV['RACK_ENV'] || 'development'

  # Only send errors in production
  config.enabled = ENV['RACK_ENV'] == 'production'

  # Framework integration
  config.framework = "Sinatra: #{Sinatra::VERSION}"
end

use Rollbar::Middleware::Rack

# Configure better_errors for development
if development?
  require 'better_errors'
  require 'binding_of_caller'

  use BetterErrors::Middleware
  # BetterErrors.application_root = __dir__
end

helpers do
  def render_page_navigation(pages = nil, current_page_id = nil)
    pages ||= OutlineClient.new.get_collection_structure
    html = "<ul>"
    pages.each do |page|
      next if page['title'].downcase.include?('[private]')

      html += page['id'] == current_page_id ? "<li class='current-page'>" : "<li>"
      html += "<a href='#{page['url']}'>#{page['title']}</a>"
      html += render_page_navigation(page['children'], current_page_id) if page['children']&.any?
      html += "</li>"
    end
    html += "</ul>"
    html
  end
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
    status 200
    erb :document
  elsif @document.error?
    @title = 'Error'
    status 500
    erb :error
  else
    @title = 'Document Not Found'
    status 404
    erb :not_found
  end
end

get '/search' do
  @query = params[:query] || params[:q]
  if @query && !@query.empty?
    @results = OutlineClient.new.search_documents(@query).map { |result| SearchResult.new(data: result) }
    @title = 'Search results'
  else
    @title = 'Search'
  end
  erb :search
end

# Sass compilation route (development only - production serves from public/)
get '/stylesheets/style.css' do
  # In production, let static file serving handle this
  pass if settings.environment == :production

  content_type 'text/css', charset: 'utf-8'
  puts "Compiling SASS for development..."
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
  # Try to find a redirect URL
  redirect_url = UrlMapper.new.get_redirect_url(request.path_info)
  redirect redirect_url, 301 if redirect_url # Permanent redirect

  @title = 'Page not found'
  erb :not_found
end
