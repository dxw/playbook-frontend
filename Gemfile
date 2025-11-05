source 'https://rubygems.org'

ruby File.read(".ruby-version").strip

gem 'connection_pool'  # Connection pooling for Redis
gem 'dotenv'           # Load environment variables from .env file
gem 'httparty'         # Simple HTTP client for making API requests to Outline
gem 'json'             # JSON parsing and generation for API responses
gem 'kramdown'         # Markdown parser
gem 'puma'             # High-performance web server for Ruby applications
gem 'rackup'           # Rack server command for running web applications
gem 'redis'            # Redis client for caching
gem 'sass-embedded'    # Embedded SASS compiler for styling
gem 'sinatra'          # Lightweight web framework for Ruby
gem 'sinatra-contrib'  # Extensions for Sinatra (includes reloader for development)

group :development do
  gem 'better_errors'  # Better error pages with interactive console
  gem 'binding_of_caller' # Provides stack frame context for better_errors
  gem 'bundle-audit'   # Security audit for Bundler dependencies
  gem 'byebug'         # Debugging tool for Ruby
  gem 'rerun'          # Automatically restart the app when files change during development
  gem 'rubocop'        # Ruby static code analyzer and formatter
end

group :test do
  gem 'factory_bot'    # Creating test data
  gem 'rack-test'      # Testing API for Rack apps
  gem 'rspec'          # Testing framework for Ruby
  gem 'simplecov'      # Code coverage analysis tool
  gem 'webmock'        # Library for stubbing HTTP requests
end
