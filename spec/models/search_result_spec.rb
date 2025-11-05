require 'spec_helper'
require_relative '../../models/search_result'

RSpec.describe SearchResult do
  describe '#initialize' do
    it 'creates a search result with context' do
      data = {
        'context'  => 'This is the search <mark>context</mark>',
        'document' => build(:document_data),
      }

      result = SearchResult.new(data: data)
      expect(result.context).to eq('This is the search <mark>context</mark>')
    end

    it 'creates an associated document' do
      data = {
        'context'  => 'Test context',
        'document' => build(:document_data, title: 'Search Result Doc'),
      }

      result = SearchResult.new(data: data)
      expect(result.doc).to be_a(Document)
      expect(result.doc.title).to eq('Search Result Doc')
    end
  end

  describe '#doc' do
    it 'provides access to the document object' do
      data = {
        'context'  => 'Test',
        'document' => build(:document_data),
      }

      result = SearchResult.new(data: data)
      expect(result.doc.id).to eq('doc123')
      expect(result.doc.title).to eq('Sample Document')
    end
  end

  describe '#context' do
    it 'returns the search context with highlights' do
      data = {
        'context'  => 'Found <mark>keyword</mark> in text',
        'document' => build(:document_data),
      }

      result = SearchResult.new(data: data)
      expect(result.context).to include('<mark>keyword</mark>')
    end
  end
end
