ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
end

require 'bundler/setup'
Bundler.require(:default, :test)

require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'factory_bot'

# Require the application
require_relative '../app'

# Configure views directory for tests
Sinatra::Application.set :views, File.expand_path('../views', __dir__)

# Load FactoryBot factories
Dir[File.join(__dir__, 'factories', '**', '*.rb')].each { |f| require f }

# Require support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods

  # Disable real HTTP requests but allow localhost and local addresses
  WebMock.disable_net_connect!(
    allow_localhost: true,
    allow: ['127.0.0.1', 'localhost', /.*\.local/]
  )

  # Clean up after each test
  config.before(:each) do
    # Set test environment variables
    ENV['OUTLINE_API_KEY'] = 'test_api_key'
    ENV['OUTLINE_COLLECTION_ID'] = 'test_collection_id'
    ENV['REDIS_URL'] = nil # Disable Redis for tests by default
    ENV['DISABLE_REDIS_CACHE'] = 'true'
  end

  config.after(:each) do
    WebMock.reset!
  end

  # RSpec configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = false
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
