require 'httparty'
require 'json'
require 'byebug' if development?
require_relative 'cache_service'

class OutlineClient
  include HTTParty

  def initialize
    @api_key = ENV.fetch('OUTLINE_API_KEY', nil)
    @collection_id = ENV.fetch('OUTLINE_COLLECTION_ID', nil)
    @cache = CacheService.new
  end

  # Documents

  def get_document(id)
    cache_key = "document_#{id}"

    @cache.fetch(cache_key, type: :document) do
      document = make_request('documents.info', { id: id })['data']
      title = document&.dig('title')
      document unless title&.downcase&.include?('[private]')
    end
  end

  def search_documents(query)
    cache_key = "search_#{@collection_id}_#{query}"

    @cache.fetch(cache_key, type: :search) do
      make_request('documents.search',
                   { query: query, collectionId: @collection_id, statusFilter: ['published'] })['data']
    end
  end

  # Attachments

  def get_attachment_url(attachment_id)
    cache_key = "attachment_#{attachment_id}"

    @cache.fetch(cache_key, type: :attachment) do
      make_request('attachments.redirect', { id: attachment_id }, follow_redirects: false)
    end
  end

  # Collections

  def get_collection
    cache_key = "collection_#{@collection_id}"

    @cache.fetch(cache_key, type: :document) do
      make_request('collections.info', { id: @collection_id })['data']
    end
  end

  def get_collection_structure
    cache_key = "collection_structure_#{@collection_id}"

    @cache.fetch(cache_key, type: :collection_structure) do
      make_request('collections.documents', { id: @collection_id })['data']
    end
  end

  private

  def make_request(endpoint, body = nil, follow_redirects: true)
    puts "Making request to #{endpoint} with body: #{body.inspect}"
    options = { headers: {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type'  => 'application/json',
    } }
    options[:body] = body.to_json if body
    options[:follow_redirects] = follow_redirects

    response = self.class.post("https://app.getoutline.com/api/#{endpoint}", options)

    # Handle redirects manually when follow_redirects is false
    return response.headers['location'] if !follow_redirects && [301, 302].include?(response.code)

    if response.success?
      JSON.parse(response.body)
    else
      { error: "API Error: #{response.code} - #{response.message}" }
    end
  end
end
