require 'spec_helper'
require_relative '../../lib/cache_service'

RSpec.describe CacheService do
  let(:service) { CacheService.new }

  describe '#initialize' do
    context 'when Redis is not available' do
      before do
        ENV['REDIS_URL'] = nil
        ENV['DISABLE_REDIS_CACHE'] = 'false'
      end

      it 'disables caching' do
        expect(service.instance_variable_get(:@caching_enabled)).to be_falsey
      end
    end

    context 'when Redis is disabled via environment variable' do
      before do
        ENV['REDIS_URL'] = 'redis://localhost:6379'
        ENV['DISABLE_REDIS_CACHE'] = 'true'
      end

      it 'disables caching' do
        expect(service.instance_variable_get(:@caching_enabled)).to be_falsey
      end
    end
  end

  describe '#fetch' do
    context 'when caching is disabled' do
      before do
        service.instance_variable_set(:@caching_enabled, false)
      end

      it 'yields the block without caching' do
        result = service.fetch('test_key', type: :document) { 'fresh_data' }
        expect(result).to eq('fresh_data')
      end
    end

    context 'when caching is enabled' do
      before do
        ENV['REDIS_URL'] = 'redis://localhost:6379'
        ENV['DISABLE_REDIS_CACHE'] = 'false'
        allow(ConnectionPool).to receive(:new).and_return(pool)
        allow(pool).to receive(:with).and_yield(redis)
        allow(redis).to receive(:ping)
        allow(redis).to receive(:setex)
      end

      let(:redis) { instance_double(Redis) }
      let(:pool) { instance_double(ConnectionPool) }

      context 'when the cache contains a value' do
        before do
          allow(redis).to receive(:get).and_return({ 'id' => '123', 'title' => 'Cached' }.to_json)
        end

        it 'returns the cached value' do
          result = service.fetch('test_key', type: :document) { 'fresh_data' }

          expect(result).to eq({ 'id' => '123', 'title' => 'Cached' })
          expect(redis).not_to have_received(:setex)
        end
      end

      context 'when the cache is empty' do
        before do
          allow(redis).to receive(:get).and_return(nil)
        end

        it 'executes block and caches result' do
          result = service.fetch('test_key', type: :document) { { 'data' => 'fresh' } }

          expect(result).to eq({ 'data' => 'fresh' })
          expect(redis).to have_received(:setex).with(
            anything,
            CacheService::CACHE_TTLS[:document],
            { 'data' => 'fresh' }.to_json
          )
        end
      end

      describe 'caching behavior' do
        before do
          allow(redis).to receive(:get).and_return(nil)
        end

        it 'uses different TTLs for different types' do
          service.fetch('search_key', type: :search) { { 'results' => [] } }

          expect(redis).to have_received(:setex).with(
            anything,
            CacheService::CACHE_TTLS[:search],
            anything
          )
        end

        it 'generates unique cache keys with SHA256' do
          service.fetch('my_unique_key', type: :document) { { 'data' => 'test' } }

          cache_key = service.send(:generate_cache_key, 'my_unique_key', :document)
          expect(cache_key).to match(/^playbook:document:[a-f0-9]{64}$/)
        end
      end

      context 'when Redis raises an error' do
        before do
          allow(redis).to receive(:get).and_raise(Redis::BaseError, 'Connection failed')
        end

        it 'falls back to executing the block' do
          result = service.fetch('test_key', type: :document) { 'fallback_data' }

          expect(result).to eq('fallback_data')
        end
      end
    end
  end
end
