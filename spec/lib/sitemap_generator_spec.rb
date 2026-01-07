require 'spec_helper'
require_relative '../../lib/sitemap_generator'

RSpec.describe SitemapGenerator do
  let(:base_url) { 'https://example.com' }
  let(:pages) do
    [
      {
        'id'        => 'page1',
        'title'     => 'Page 1',
        'updatedAt' => '2025-01-01T12:00:00Z',
        'children'  => [
          {
            'id'        => 'page1-1',
            'title'     => 'Page 1.1',
            'updatedAt' => '2025-01-02T12:00:00Z',
            'children'  => [],
          },
        ],
      },
      {
        'id'        => 'page2',
        'title'     => 'Page 2',
        'updatedAt' => '2025-01-03T12:00:00Z',
        'children'  => [],
      },
      {
        'id'        => 'page3',
        'title'     => '[Private] Secret Page',
        'updatedAt' => '2025-01-04T12:00:00Z',
        'children'  => [],
      },
    ]
  end

  describe '#generate' do
    let(:xml) do
      SitemapGenerator.new(base_url: base_url, pages: pages).generate
    end

    it 'generates a valid XML sitemap' do
      expect(xml).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      expect(xml).to end_with('</urlset>')
    end

    it 'includes the homepage' do
      expect(xml).to match(%r{<url>.*?<loc>https://example\.com/</loc>.*?</url>}m)
    end

    it 'includes the search page' do
      expect(xml).to match(%r{<url>.*?<loc>https://example\.com/search</loc>.*?</url>}m)
    end

    it 'includes document pages with their IDs' do
      expect(xml).to include('<loc>https://example.com/doc/page1</loc>')
      expect(xml).to include('<loc>https://example.com/doc/page2</loc>')
    end

    it 'includes lastmod dates for documents' do
      expect(xml).to include('<lastmod>2025-01-01</lastmod>')
      expect(xml).to include('<lastmod>2025-01-03</lastmod>')
    end

    it 'includes nested pages' do
      expect(xml).to include('<loc>https://example.com/doc/page1-1</loc>')
      expect(xml).to include('<lastmod>2025-01-02</lastmod>')
    end

    it 'excludes private pages' do
      expect(xml).not_to include('<loc>https://example.com/doc/page3</loc>')
    end

    context 'when a page lacks updatedAt' do
      let(:pages) do
        [
          {
            'id'       => 'page_no_date',
            'title'    => 'No Date Page',
            'children' => [],
          },
        ]
      end

      it 'handles pages without updatedAt gracefully' do
        expect(xml).to include('<loc>https://example.com/doc/page_no_date</loc>')
        # Check that there's no lastmod tag in the URL entry for this page
        page_entry = xml.match(%r{<url>\s*<loc>https://example\.com/doc/page_no_date</loc>.*?</url>}m)[0]
        expect(page_entry).not_to include('<lastmod>')
      end
    end

    context 'when pages array is empty' do
      let(:pages) { [] }

      it 'handles empty pages array' do
        expect(xml).to include('<loc>https://example.com/</loc>')
        expect(xml).to include('<loc>https://example.com/search</loc>')
        expect(xml).to include('</urlset>')
      end
    end
  end
end
