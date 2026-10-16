require 'spec_helper'
require_relative '../../models/document'

RSpec.describe Document do
  let(:outline_client) { instance_double(OutlineClient) }

  before do
    allow(OutlineClient).to receive(:new).and_return(outline_client)
  end

  describe '#initialize' do
    context 'with data provided' do
      it 'creates a document from the provided data' do
        doc = Document.new(data: build(:document_data))
        expect(doc.id).to eq('doc123')
        expect(doc.title).to eq('Sample Document')
      end
    end

    context 'with id provided' do
      it 'fetches the document from the API' do
        expect(outline_client).to receive(:get_document)
          .with('doc123')
          .and_return(build(:document_data))

        doc = Document.new(id: 'doc123')
        expect(doc.id).to eq('doc123')
      end
    end

    context 'as a collection' do
      it 'marks the document as a collection' do
        doc = Document.new(data: build(:collection_data), is_collection: true)
        expect(doc.id).to eq('col123')
      end
    end
  end

  describe '#valid?' do
    it 'returns true for a valid document' do
      doc = Document.new(data: build(:document_data))
      expect(doc).to be_valid
    end

    it 'returns false for nil data' do
      allow(outline_client).to receive(:get_document).with(nil).and_return(nil)
      doc = Document.new(data: nil)
      expect(doc).not_to be_valid
    end

    it 'returns false for empty data' do
      doc = Document.new(data: {})
      expect(doc).not_to be_valid
    end

    it 'returns false for error response' do
      doc = Document.new(data: { 'error' => 'Not found' })
      expect(doc).not_to be_valid
    end
  end

  describe '#error?' do
    it 'returns true when document has an error' do
      doc = Document.new(data: { 'error' => 'API Error' })
      expect(doc).to be_error
    end

    it 'returns false for valid document' do
      doc = Document.new(data: build(:document_data))
      expect(doc).not_to be_error
    end
  end

  describe '#error_message' do
    it 'returns the error message' do
      doc = Document.new(data: { 'error' => 'Not found' })
      expect(doc.error_message).to eq('Not found')
    end
  end

  describe '#content' do
    it 'keeps three-space-indented ordered lists inside their parent item' do
      markdown = <<~MARKDOWN
        1. Is the person working on a project that can supply configured IT hardware?
        2.
           1. Arrange for this IT hardware to be provided.
           2. If time scales are too short then dxw will provide IT hardware, if the client permits this.
        3. Are they from an approved agency?
      MARKDOWN
      doc = Document.new(data: build(:document_data, text: markdown))

      expect(doc.content.gsub(/\s+/, ' ')).to eq(
        '<ol> ' \
        '<li>Is the person working on a project that can supply configured IT hardware?</li> ' \
        '<li> <ol> ' \
        '<li>Arrange for this IT hardware to be provided.</li> ' \
        '<li>If time scales are too short then dxw will provide IT hardware, if the client permits this.</li> ' \
        '</ol> </li> ' \
        '<li>Are they from an approved agency?</li> ' \
        '</ol>'
      )
    end

    it 'keeps unordered subitems nested inside an ordered list' do
      markdown = <<~MARKDOWN
        1. Hardware
           - Laptop
             - Charger
        2. Accounts
      MARKDOWN
      doc = Document.new(data: build(:document_data, text: markdown))

      expect(doc.content.gsub(/\s+/, ' ')).to eq(
        '<ol> <li>Hardware <ul> <li>Laptop <ul> <li>Charger</li> </ul> </li> </ul> </li> <li>Accounts</li> </ol>'
      )
    end

    it 'nests children when the empty parent has trailing whitespace and blank lines' do
      markdown = "1. Before\n\n2. \n\n   1. Nested one\n   2. Nested two\n\n3. After\n"
      doc = Document.new(data: build(:document_data, text: markdown))

      expect(doc.content).to match(%r{<li>\s*<ol>\s*<li>Nested one</li>\s*<li>Nested two</li>\s*</ol>\s*</li>})
      expect(doc.content.scan('<ol>').length).to eq(2)
    end

    {
      'formatted headings'   => '## A **bold** heading',
      'smart punctuation'    => %q("Hello" -- wait... it's fine.),
      'footnotes'            => "A note[^1].\n\n[^1]: Footnote content.\n",
      'definition lists'     => "Term\n: Definition\n",
      'attributes'           => "Text\n{: .notice}\n",
      'tables'               => "| Name | Value |\n| --- | ---: |\n| One | Two |\n",
      'inline syntax'        => ':warning: ~~removed~~ https://example.com',
      'task lists'           => "- [ ] Pending\n- [x] Done\n",
      'ordinary lists'       => "1. Before\n2. Parent\n   1. Child\n3. After\n",
      'four-space nesting'   => "1. Before\n2. \n    1. Child\n3. After\n",
      'empty sibling items'  => "1. Before\n2. \n3. After\n",
      'fenced code'          => "~~~\n1. Before\n2.\n   1. Literal child\n~~~\n",
      'backtick-fenced code' => "```\n1. Before\n2.\n   1. Literal child\n```\n",
      'unclosed fenced code' => "~~~\n1. Before\n2.\n   1. Literal child\n",
      'indented code'        => "    1. Before\n    2.\n       1. Literal child\n",
    }.each do |name, markdown|
      it "preserves existing Kramdown rendering for #{name}" do
        doc = Document.new(data: build(:document_data, text: markdown))
        expected = Kramdown::Document.new(markdown.gsub('```', '~~~')).to_html

        expect(doc.content).to eq(doc.send(:add_anchor_headings, expected).strip)
      end
    end

    it 'converts markdown to HTML' do
      doc = Document.new(data: build(:document_data, text: '# Hello\n\nThis is **bold** text.'))

      html = doc.content
      expect(html).to include('<h1')
      expect(html).to include('<strong>bold</strong>')
    end

    it 'adds anchor links to headings' do
      doc = Document.new(data: build(:document_data, text: '# Test Heading'))

      html = doc.content
      expect(html).to include('id="h-test-heading"')
      expect(html).to include('href="#h-test-heading"')
    end

    it 'replaces outline.com URLs' do
      doc = Document.new(data: build(:document_data, text: '[Link](https://dxw.getoutline.com/doc/test-doc123)'))

      html = doc.content
      expect(html).to include('href="/doc/test-doc123"')
      expect(html).not_to include('dxw.getoutline.com')
    end

    it 'handles attachment URLs' do
      allow(outline_client).to receive(:get_attachment_url)
        .and_return('https://s3.amazonaws.com/file.pdf')

      doc = Document.new(data: build(:document_data, text: '![File](/api/attachments.redirect?id=attach123)'))

      html = doc.content
      expect(html).to include('https://s3.amazonaws.com/file.pdf')
    end

    context 'for collections' do
      it 'uses description instead of text' do
        doc = Document.new(
          data: build(:collection_data, description: '# Collection Info'),
          is_collection: true
        )

        expect(doc.content).to include('<h1')
      end
    end
  end

  describe '#excerpt' do
    it 'returns plain text excerpt' do
      doc = Document.new(data: build(:document_data, text: '# Header\n\nThis is some text.'))

      excerpt = doc.excerpt
      expect(excerpt).not_to include('#')
      expect(excerpt).to include('This is some text')
    end

    it 'truncates long content' do
      long_text = 'a' * 400
      doc = Document.new(data: build(:document_data, text: long_text))

      excerpt = doc.excerpt
      expect(excerpt.length).to be <= 304 # 300 + '...'
      expect(excerpt).to end_with('...')
    end
  end

  describe '#children' do
    it 'returns children for a document' do
      structure = [
        {
          'id'       => 'doc123',
          'children' => [
            { 'id' => 'child1', 'title' => 'Child 1' },
            { 'id' => 'child2', 'title' => 'Child 2' },
          ],
        },
      ]

      allow(outline_client).to receive(:get_collection_structure)
        .and_return(structure)

      doc = Document.new(data: build(:document_data))
      expect(doc.children.length).to eq(2)
      expect(doc.children.first['id']).to eq('child1')
    end

    it 'returns empty array for collections' do
      doc = Document.new(data: build(:collection_data), is_collection: true)
      expect(doc.children).to eq([])
    end
  end

  describe '#edit_url' do
    it 'returns edit URL for regular documents' do
      doc = Document.new(data: build(:document_data))
      expect(doc.edit_url).to end_with('/edit')
    end

    it 'returns overview URL for collections' do
      doc = Document.new(data: build(:collection_data), is_collection: true)
      expect(doc.edit_url).to end_with('/overview')
    end
  end

  describe '#updated_at' do
    it 'parses the updated timestamp' do
      doc = Document.new(data: build(:document_data))
      expect(doc.updated_at).to be_a(Time)
      expect(doc.updated_at.year).to eq(2025)
    end

    it 'returns nil when timestamp is missing' do
      doc = Document.new(data: build(:document_data, updatedAt: nil))
      expect(doc.updated_at).to be_nil
    end
  end
end
