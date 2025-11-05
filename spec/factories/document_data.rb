FactoryBot.define do
  factory :document_data, class: Hash do
    skip_create

    id { 'doc123' }
    title { 'Sample Document' }
    text { "# Sample Document\n\nThis is a sample document." }
    url { "https://app.getoutline.com/doc/sample-document-#{id}" }
    parentDocumentId { nil }
    updatedAt { '2025-01-01T12:00:00.000Z' }

    initialize_with { attributes.stringify_keys }

    trait :private do
      id { 'private123' }
      title { '[PRIVATE] Secret Document' }
    end

    trait :with_parent do
      parentDocumentId { 'parent123' }
    end

    trait :with_long_text do
      text do
        <<~TEXT
          # Long Document

          #{'Lorem ipsum dolor sit amet. ' * 50}
        TEXT
      end
    end

    trait :with_attachments do
      text do
        <<~TEXT
          # Document with attachments

          ![Image](/api/attachments.redirect?id=attachment123)

          Some content here.
        TEXT
      end
    end

    trait :with_internal_links do
      text do
        <<~TEXT
          # Document with links

          [Internal link](https://dxw.getoutline.com/doc/other-doc)
          [External link](https://example.com)
        TEXT
      end
    end
  end
end
