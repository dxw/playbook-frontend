class SitemapGenerator
  def initialize(base_url:, pages:)
    @base_url = base_url
    @pages = pages
  end

  def generate
    xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    xml += "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"

    # Add homepage
    xml += build_url_entry(
      loc: "#{@base_url}/"
    )

    # Add search page
    xml += build_url_entry(
      loc: "#{@base_url}/search"
    )

    # Add all document pages
    xml += add_pages_to_sitemap(@pages)
    xml += '</urlset>'

    xml
  end

  private

  def build_url_entry(loc:, lastmod: nil)
    entry = "  <url>\n"
    entry += "    <loc>#{loc}</loc>\n"
    entry += "    <lastmod>#{lastmod}</lastmod>\n" if lastmod
    entry += "  </url>\n"
    entry
  end

  def add_pages_to_sitemap(pages, xml_str = '')
    pages.each do |page|
      # Skip private pages
      next if page['title'].downcase.include?('[private]')

      lastmod = page['updatedAt'] ? Time.parse(page['updatedAt']).strftime('%Y-%m-%d') : nil

      xml_str += build_url_entry(
        loc: "#{@base_url}/doc/#{page['id']}",
        lastmod: lastmod
      )

      # Recursively add children
      xml_str = add_pages_to_sitemap(page['children'], xml_str) if page['children']&.any?
    end
    xml_str
  end
end
