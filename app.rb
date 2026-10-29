require 'sinatra'
require 'sinatra/reloader' if development?
require 'dotenv/load'
require 'kramdown'
require 'omniauth-saml'
require 'sass-embedded'
require 'byebug' if development?
require 'rollbar'
require_relative 'lib/outline_client'
require_relative 'lib/authentication'
require_relative 'lib/url_mapper'
require_relative 'lib/sitemap_generator'
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

session_secret = ENV.fetch('SESSION_SECRET') do
  raise 'SESSION_SECRET must be configured in production' if production?

  'test-session-secret-must-be-at-least-64-characters-long-for-cookie-security'
end

use Rack::Session::Cookie,
    key: 'playbook.session',
    secret: session_secret,
    same_site: :lax,
    secure: production?

use OmniAuth::Builder do
  provider :saml,
           assertion_consumer_service_url: ENV.fetch('SAML_ASSERTION_CONSUMER_SERVICE_URL', nil),
           sp_entity_id: ENV.fetch('SAML_SP_ENTITY_ID', nil),
           idp_sso_service_url: ENV.fetch('SAML_IDP_SSO_SERVICE_URL', nil),
           idp_cert: ENV.fetch('SAML_IDP_CERT', nil)&.gsub('\\n', "\n"),
           name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
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
  def signed_in?
    Authentication.signed_in?(session)
  end

  def private_page?(page)
    page['title'].downcase.include?('[private]')
  end

  def visible_page?(page)
    !private_page?(page) || signed_in?
  end

  def render_page_navigation(pages = nil, current_page_id = nil)
    pages ||= OutlineClient.new.get_collection_structure
    html = "<ul>"
    pages.each do |page|
      next unless visible_page?(page)

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
post '/auth/saml/callback' do
  Authentication.sign_in(session, request.env['omniauth.auth'])
  halt 403, 'Only dxw accounts can access private playbook pages.' unless signed_in?

  redirect '/'
end

get '/auth/failure' do
  @title = 'Sign in failed'
  status 401
  erb :error
end

post '/sign-out' do
  Authentication.sign_out(session)
  redirect '/'
end

get '/' do
  @document = Document.new(data: OutlineClient.new.get_collection, is_collection: true)
  @title = 'dxw’s Playbook'
  erb :document
end

get '/doc/:id' do
  @document = Document.new(id: params[:id])
  if @document.valid? && visible_page?(@document.doc)
    @title = @document.title
    status 200
    erb :document
  elsif @document.error?
    @title = 'Error'
    status 500
    erb :error
  else
    @title = 'Document not found'
    status 404
    erb :not_found
  end
end

get '/search' do
  @query = params[:query] || params[:q]
  if @query && !@query.empty?
    @results = OutlineClient.new.search_documents(@query).map do |result|
      if visible_page?(result['document'])
        SearchResult.new(data: result)
      else
        @has_private_results = true
        next
      end
    end.compact
    @title = 'Search results'
  else
    @title = 'Search'
  end
  erb :search
end

get '/sitemap.xml' do
  content_type 'application/xml', charset: 'utf-8'

  pages = OutlineClient.new.get_collection_structure
  SitemapGenerator.new(base_url: request.base_url, pages: pages).generate
end

# Sass compilation route (development only - production serves from public/)
get '/assets/stylesheets/style.css' do
  # In production, let static file serving handle this
  pass if settings.environment == :production

  content_type 'text/css', charset: 'utf-8'
  puts "Compiling Sass for development..."
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
