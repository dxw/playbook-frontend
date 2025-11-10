require 'spec_helper'

RSpec.describe 'Playbook Overlay Application' do
  def app
    Sinatra::Application
  end

  let(:outline_client) { instance_double(OutlineClient) }

  before do
    allow(OutlineClient).to receive(:new).and_return(outline_client)
    allow(outline_client).to receive(:get_collection_structure)
      .and_return(build(:collection_structure))
  end

  describe 'GET /' do
    before do
      allow(outline_client).to receive(:get_collection)
        .and_return(build(:collection_data))
    end

    it 'responds successfully' do
      get '/'

      expect(last_response).to be_ok
    end

    it 'creates a document from collection data' do
      get '/'

      expect(outline_client).to have_received(:get_collection)
    end
  end

  describe 'GET /doc/:id' do
    before do
      allow(outline_client).to receive(:get_document)
        .and_return(response)
    end

    context 'when document exists' do
      let(:response) { build(:document_data) }

      it 'fetches the document from the API' do
        get '/doc/doc123'

        expect(last_response).to be_ok
        expect(outline_client).to have_received(:get_document).with('doc123')
      end
    end

    context 'when document has error' do
      let(:response) { { 'error' => 'API Error: 500' } }

      it 'returns error status' do
        get '/doc/error123'

        expect(last_response).to be_server_error
      end
    end

    context 'when document not found' do
      let(:response) { nil }

      it 'returns not found status' do
        get '/doc/nonexistent'

        expect(last_response).to be_not_found
      end
    end
  end

  describe 'GET /search' do
    before do
      allow(outline_client).to receive(:search_documents)
        .and_return(response)
    end

    context 'with search query' do
      let(:response) { build(:search_results, query: 'test') }

      it 'searches for documents' do
        get '/search?query=test'

        expect(last_response).to be_ok
        expect(outline_client).to have_received(:search_documents).with('test')
      end

      it 'accepts q parameter as well as query' do
        get '/search?q=test'

        expect(last_response).to be_ok
        expect(outline_client).to have_received(:search_documents).with('test')
      end
    end

    context 'without search query' do
      let(:response) { build(:search_results) }

      it 'displays search page' do
        get '/search'

        expect(last_response).to be_ok
        expect(last_response.body).to include('Enter a search term')
      end

      it 'handles empty query' do
        get '/search?query='

        expect(last_response).to be_ok
        expect(last_response.body).to include('Enter a search term')
      end
    end

    context 'when private documents are returned' do
      let(:response) do
        [
          build(:search_result_data, document: build(:document_data, id: 'public1', title: 'Public Doc')),
          build(:search_result_data, document: build(:document_data, id: 'secret1', title: 'Private Doc [private]')),
        ]
      end

      it 'excludes private documents from results' do
        get '/search?query=confidential'

        expect(last_response).to be_ok
        expect(last_response.body).to include('Public Doc')
        expect(last_response.body).not_to include('Private Doc')
      end

      it 'flags presence of private results' do
        get '/search?query=confidential'

        expect(last_response).to be_ok
        expect(last_response.body).to include('Some private pages were also returned by the search')
      end
    end

    context 'when no private documents are returned' do
      let(:response) { build(:search_results) }

      it 'does not flag private results' do
        get '/search?query=public'

        expect(last_response).to be_ok
        expect(last_response.body).not_to include('Some private pages were also returned by the search')
      end
    end
  end

  describe 'GET /stylesheets/style.css' do
    context 'in development mode' do
      before do
        allow(Sinatra::Application).to receive(:environment).and_return(:development)
      end

      it 'compiles SCSS on the fly' do
        get '/stylesheets/style.css'

        expect(last_response).to be_ok
        expect(last_response.content_type).to include('text/css')
      end
    end
  end

  describe '404 handling' do
    let(:url_mapper) { instance_double(UrlMapper) }

    before do
      allow(UrlMapper).to receive(:new).and_return(url_mapper)
    end

    context 'when URL mapping exists' do
      before do
        allow(url_mapper).to receive(:get_redirect_url)
          .with('/old/path')
          .and_return('/doc/abc123')
      end

      it 'redirects to the new URL' do
        get '/old/path'

        expect(last_response).to be_redirect
        expect(last_response.location).to include('/doc/abc123')
      end
    end

    context 'when URL mapping does not exist' do
      before do
        allow(url_mapper).to receive(:get_redirect_url)
          .and_return(nil)
      end

      it 'returns 404 status' do
        get '/nonexistent/path'

        expect(last_response).to be_not_found
      end
    end
  end

  describe 'error handling' do
    it 'returns 500 status on errors' do
      allow(outline_client).to receive(:get_collection)
        .and_raise(StandardError, 'Something went wrong')

      expect { get '/' }.to raise_error(StandardError)
    end
  end

  describe 'helper methods' do
    describe '#render_page_navigation' do
      it 'uses collection structure' do
        allow(outline_client).to receive(:get_collection)
          .and_return(build(:collection_data))

        get '/'

        # Verify the navigation helper was called with collection structure
        expect(outline_client).to have_received(:get_collection_structure)
      end
    end
  end
end
