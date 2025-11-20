require 'kramdown'

class Document
  attr_reader :doc

  def initialize(id: nil, data: nil, is_collection: false)
    @doc = data || outline_client.get_document(id)
    @is_collection = is_collection
  end

  def id
    @doc['id']
  end

  def title
    @doc['title']
  end

  def raw_content
    @is_collection ? @doc['description'] : @doc['text']
  end

  def content
    md_to_html(raw_content).strip
  end

  def excerpt
    text = md_to_plain_text(raw_content)
    text.length > 300 ? "#{text[0..300]}..." : text
  end

  def url
    @doc['url']
  end

  def edit_url
    @is_collection ? "#{@doc['url']}/overview" : "#{@doc['url']}/edit"
  end

  def updated_at
    @doc['updatedAt'] ? Time.parse(@doc['updatedAt']) : nil
  end

  def children
    return [] if @is_collection

    @children ||= find_in_structure(id)['children']
  end

  def valid?
    !@doc.nil? && !@doc.empty? && !error?
  end

  def error?
    @doc&.key?('error')
  end

  def error_message
    @doc['error'] if error?
  end

  private

  def find_in_structure(target_id)
    structure = outline_client.get_collection_structure
    queue = structure.dup

    until queue.empty?
      current = queue.shift
      return current if current['id'] == target_id

      queue.concat(current['children']) if current['children']
    end

    nil
  end

  def md_to_html(markdown)
    return '' unless markdown

    # Process markdown through the same helpers used in the app
    processed_content = markdown.gsub('https://dxw.getoutline.com', '')

    # Handle attachments
    processed_content.gsub!(%r{/api/attachments\.redirect\?id=([^" ]+)}) do |_match|
      attachment_id = Regexp.last_match(1)
      outline_client.get_attachment_url(attachment_id)
    end

    html = Kramdown::Document.new(processed_content).to_html
    add_anchor_headings(html)
  end

  def md_to_plain_text(markdown)
    return '' unless markdown

    # Simple conversion: remove markdown syntax to get plain text
    text = markdown.dup
    text.gsub!(/!\[.*?\]\(.*?\)/, '')          # Remove images
    text.gsub!(/\[([^\]]+)\]\(.*?\)/, '\1')    # Convert links to just the text
    text.gsub!(/[#>*_`~-]/, '')                # Remove other markdown characters
    text.gsub!(/\n{2,}/, "\n") # Collapse multiple newlines
    text.strip
  end

  def outline_client
    @outline_client ||= OutlineClient.new
  end

  def add_anchor_headings(html)
    html.gsub(%r{<h([1-6])[^>]*>([^<]+)</h\1>}) do |_match|
      level = Regexp.last_match(1)
      content = Regexp.last_match(2)
      anchor_id = content.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

      %(<h#{level} id="#{anchor_id}">#{content} <a href="##{anchor_id}" aria-label="Permalink to #{content}">#</a></h#{level}>)
    end
  end
end
