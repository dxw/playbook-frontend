module ApiHelpers
  def stub_outline_document_request(id, response_data, status: 200)
    stub_request(:post, "https://app.getoutline.com/api/documents.info")
      .with(
        body: { id: id }.to_json
      )
      .to_return(
        status: status,
        body: { data: response_data }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_outline_search_request(query, response_data)
    stub_request(:post, "https://app.getoutline.com/api/documents.search")
      .with(
        body: {
          query: query,
          collectionId: ENV.fetch('OUTLINE_COLLECTION_ID', nil),
          statusFilter: ['published'],
        }.to_json
      )
      .to_return(
        status: 200,
        body: { data: response_data }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_outline_collection_request(response_data)
    stub_request(:post, "https://app.getoutline.com/api/collections.info")
      .with(
        body: { id: ENV.fetch('OUTLINE_COLLECTION_ID', nil) }.to_json
      )
      .to_return(
        status: 200,
        body: { data: response_data }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_outline_collection_structure_request(response_data)
    stub_request(:post, "https://app.getoutline.com/api/collections.documents")
      .with(
        body: { id: ENV.fetch('OUTLINE_COLLECTION_ID', nil) }.to_json
      )
      .to_return(
        status: 200,
        body: { data: response_data }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_outline_attachment_redirect(attachment_id, redirect_url)
    stub_request(:post, "https://app.getoutline.com/api/attachments.redirect")
      .with(
        body: { id: attachment_id }.to_json
      )
      .to_return(
        status: 302,
        headers: { 'location' => redirect_url }
      )
  end
end

RSpec.configure do |config|
  config.include ApiHelpers
end
