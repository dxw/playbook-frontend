require 'httparty'
require 'json'
require 'byebug' if development?

class OutlineClient
  include HTTParty

  def initialize
    @api_key = ENV.fetch('OUTLINE_API_KEY', nil)
    @collection_id = ENV.fetch('OUTLINE_COLLECTION_ID', nil)
  end

  # Documents

  def get_document(id)
    make_request('documents.info', { id: id })['data']
  end

  def search_documents(query)
    make_request('documents.search',
                 { query: query, collectionId: @collection_id, statusFilter: ['published'] })['data']
  end

  # Attachments

  def get_attachment_url(attachment_id)
    make_request('attachments.redirect', { id: attachment_id }, follow_redirects: false)
  end

  # Collections

  def get_collection
    make_request('collections.info', { id: @collection_id })['data']
  end

  def get_collection_structure
    @get_collection_structure ||= make_request('collections.documents', { id: @collection_id })['data']
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
