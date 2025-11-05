require 'spec_helper'
require_relative '../../lib/url_mapper'

RSpec.describe UrlMapper do
  let(:csv_file) { 'spec/fixtures/test_mapping.csv' }
  let(:mapper) { UrlMapper.new(csv_file) }

  before do
    # Create test CSV file
    FileUtils.mkdir_p('spec/fixtures')
    CSV.open(csv_file, 'w') do |csv|
      csv << %w[old_url new_url title migrated_at]
      csv << [
        '/guides/getting-started',
        'https://app.getoutline.com/doc/getting-started-abc123',
        'Getting Started',
        '2025-01-01',
      ]
      csv << [
        '/handbook/security',
        'https://app.getoutline.com/doc/security-guidelines-def456',
        'Security Guidelines',
        '2025-01-02',
      ]
      csv << [
        '/about/team/',
        'https://app.getoutline.com/doc/our-team-ghi789',
        'Our Team',
        '2025-01-03',
      ]
    end
  end

  after do
    # Clean up test CSV file
    FileUtils.rm_f(csv_file)
  end

  describe '#initialize' do
    it 'loads mappings from CSV file' do
      expect(mapper.instance_variable_get(:@mappings).length).to eq(3)
    end

    it 'handles missing CSV file gracefully' do
      mapper = UrlMapper.new('nonexistent.csv')
      expect(mapper.instance_variable_get(:@mappings)).to eq([])
    end
  end

  describe '#find_mapping' do
    let(:mapping) { mapper.find_mapping(path) }

    context 'when URL exactly matches the mapping' do
      let(:path) { '/guides/getting-started' }

      it 'finds the match' do
        expect(mapping).not_to be_nil
        expect(mapping[:title]).to eq('Getting Started')
      end
    end

    context 'when URL has trailing slash' do
      let(:path) { '/guides/getting-started/' }

      it 'finds the match' do
        expect(mapping).not_to be_nil
        expect(mapping[:title]).to eq('Getting Started')
      end
    end

    context 'when URL has no leading slash' do
      let(:path) { 'guides/getting-started' }

      it 'finds the match' do
        expect(mapping).not_to be_nil
        expect(mapping[:title]).to eq('Getting Started')
      end
    end

    context 'when URL has protocol and domain' do
      let(:path) { 'https://example.com/guides/getting-started' }

      it 'finds the match' do
        expect(mapping).not_to be_nil
        expect(mapping[:title]).to eq('Getting Started')
      end
    end

    context 'when the URL does not match any mapping' do
      let(:path) { '/nonexistent/path' }

      it 'returns nil' do
        expect(mapping).to be_nil
      end
    end
  end

  describe '#get_redirect_url' do
    let(:redirect_url) { mapper.get_redirect_url(path) }

    context 'when mapping exists' do
      let(:path) { '/guides/getting-started' }

      it 'extracts document ID from new URL' do
        expect(redirect_url).to eq('/doc/abc123')
      end
    end

    context 'when mapping does not exist' do
      let(:path) { '/unknown/path' }

      it 'returns nil' do
        expect(redirect_url).to be_nil
      end
    end
  end

  describe 'URL normalization' do
    it 'normalizes URLs consistently' do
      urls = [
        '/guides/getting-started',
        '/guides/getting-started/',
        'guides/getting-started',
        'https://example.com/guides/getting-started',
        'http://example.com/guides/getting-started/',
      ]

      normalized = urls.map { |url| mapper.send(:normalize_url, url) }
      expect(normalized.uniq.length).to eq(1)
      expect(normalized.first).to eq('/guides/getting-started')
    end

    it 'handles empty URLs' do
      expect(mapper.send(:normalize_url, '')).to eq('')
      expect(mapper.send(:normalize_url, nil)).to eq('')
    end
  end
end
