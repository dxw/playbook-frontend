require 'spec_helper'
require_relative '../../lib/outline_client'

RSpec.describe OutlineClient do
  let(:client) { OutlineClient.new }

  before do
    ENV['OUTLINE_API_KEY'] = 'test_api_key'
    ENV['OUTLINE_COLLECTION_ID'] = 'test_collection_id'
  end

  describe '#get_document' do
    before do
      stub_outline_document_request('doc123', document_data)
    end

    let(:document_data) { build(:document_data) }
    let(:result) { client.get_document('doc123') }

    it 'fetches a document by id' do
      expect(result['id']).to eq('doc123')
      expect(result['title']).to eq('Sample Document')
    end

    context 'when the document is private' do
      let(:document_data) { build(:document_data, :private) }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when a document is cached' do
      let(:cache) { instance_double(CacheService) }
      before do
        allow(CacheService).to receive(:new).and_return(cache)
        allow(cache).to receive(:fetch).with('document_doc123', type: :document)
                                       .and_yield
                                       .and_return(build(:document_data))
      end

      it 'uses the cache' do
        result
        expect(cache).to have_received(:fetch).with('document_doc123', type: :document)
        expect(result['id']).to eq('doc123')
      end
    end

    context 'when the document does not exist' do
      before do
        stub_outline_document_request('nonexistent', { 'error' => 'Not found' }, status: 404)
      end

      it 'returns nil' do
        result = client.get_document('nonexistent')
        expect(result).to be_nil
      end
    end
  end

  describe '#search_documents' do
    let(:search_results) { build(:search_results) }
    let(:response) { client.search_documents(query) }
    let(:query) { 'test' }
    before do
      stub_outline_search_request(query, search_results)
    end

    it 'searches for documents' do
      expect(response.length).to eq(2)
      expect(response.first['document']['title']).to include('Sample Document')
    end

    context 'when the cache is available' do
      let(:cache) { instance_double(CacheService) }
      before do
        allow(CacheService).to receive(:new).and_return(cache)
        allow(cache).to receive(:fetch)
          .with("search_#{ENV.fetch('OUTLINE_COLLECTION_ID', nil)}_#{query}", type: :search)
          .and_yield
          .and_return(build(:search_results))
      end

      it 'uses cache for search results' do
        response
        expect(cache).to have_received(:fetch)
        expect(response.length).to eq(2)
      end
    end
  end

  describe '#get_attachment_url' do
    it 'fetches redirect URL for an attachment' do
      stub_outline_attachment_redirect('attach123', 'https://s3.aws.com/file.pdf')

      url = client.get_attachment_url('attach123')
      expect(url).to eq('https://s3.aws.com/file.pdf')
    end

    it 'uses cache for attachment URLs' do
      cache = instance_double(CacheService)
      allow(CacheService).to receive(:new).and_return(cache)
      allow(cache).to receive(:fetch)
        .with('attachment_attach123', type: :attachment)
        .and_yield
        .and_return('https://s3.aws.com/cached.pdf')

      stub_outline_attachment_redirect('attach123', 'https://s3.aws.com/cached.pdf')

      url = client.get_attachment_url('attach123')
      expect(url).to eq('https://s3.aws.com/cached.pdf')
    end
  end

  describe '#get_collection' do
    before do
      stub_outline_collection_request(build(:collection_data))
    end
    let(:result) { client.get_collection }

    it 'fetches collection data' do
      expect(result['id']).to eq('col123')
      expect(result['name']).to eq('Playbook')
    end

    context 'when the cache is available' do
      let(:cache) { instance_double(CacheService) }
      before do
        allow(CacheService).to receive(:new).and_return(cache)
        allow(cache).to receive(:fetch)
          .with('collection_test_collection_id', type: :document)
          .and_yield
          .and_return(build(:collection_data))
      end

      it 'uses cache for collection data' do
        result
        expect(cache).to have_received(:fetch)
        expect(result['id']).to eq('col123')
      end
    end
  end

  describe '#get_collection_structure' do
    let(:result) { client.get_collection_structure }
    before do
      stub_outline_collection_structure_request(build(:collection_structure))
    end

    it 'fetches the collection document structure' do
      expect(result.length).to eq(2)
      expect(result.first['title']).to eq('Introduction')
      expect(result.first['children'].length).to eq(1)
    end

    context 'when the cache is available' do
      let(:cache) { instance_double(CacheService) }
      before do
        allow(CacheService).to receive(:new).and_return(cache)
        allow(cache).to receive(:fetch)
          .with('collection_structure_test_collection_id', type: :collection_structure)
          .and_yield
          .and_return(build(:collection_structure))
      end

      it 'uses cache for structure data' do
        result
        expect(cache).to have_received(:fetch)
        expect(result.length).to eq(2)
      end
    end
  end
end
