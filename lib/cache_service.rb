require 'redis'
require 'connection_pool'
require 'json'
require 'digest'

class CacheService
  # Cache TTL settings (in seconds)
  CACHE_TTLS = {
    document: 60 * 60,             # 1 hour for documents
    collection_structure: 60 * 60, # 1 hour for collection structure
    search: 60 * 5,                # 5 minutes for search results
    attachment: 60 * 60,           # 1 hour for attachment URLs
  }.freeze

  def initialize
    @caching_enabled = ENV.fetch('REDIS_URL', nil) && ENV.fetch('DISABLE_REDIS_CACHE', 'false').to_s.downcase == 'false'
    setup_cache if @caching_enabled
    puts "Cache: #{@caching_enabled ? 'enabled' : 'disabled'}"
  end

  def fetch(key, type: :document, &)
    cache_key = generate_cache_key(key, type)
    ttl = CACHE_TTLS[type] || CACHE_TTLS[:document]

    if @caching_enabled
      fetch_from_redis(cache_key, ttl, &)
    elsif block_given?
      yield
    end
  end

  private

  def setup_cache
    @redis_pool = ConnectionPool.new(size: 5, timeout: 5) do
      Redis.new(url: ENV.fetch('REDIS_URL'))
    end
    # Test connection
    @redis_pool.with(&:ping)
    puts "Redis cache connected successfully"
  rescue StandardError => e
    puts "Redis connection failed: #{e.message}. Caching disabled."
    @caching_enabled = false
  end

  def generate_cache_key(key, type)
    key_hash = Digest::SHA256.hexdigest(key.to_s)
    "playbook:#{type}:#{key_hash}"
  end

  def fetch_from_redis(cache_key, ttl)
    @redis_pool.with do |conn|
      cached_value = conn.get(cache_key)
      if cached_value
        JSON.parse(cached_value)
      else
        result = yield if block_given?
        conn.setex(cache_key, ttl, result.to_json) if result
        result
      end
    end
  rescue Redis::BaseError => e
    puts "Redis error: #{e.message}. Executing without cache."
    yield if block_given?
  end
end
