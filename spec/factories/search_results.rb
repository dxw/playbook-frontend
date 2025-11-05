FactoryBot.define do
  factory :search_results, class: Array do
    skip_create

    transient do
      query { 'test' }
      count { 2 }
    end

    initialize_with do
      [
        {
          'ranking'  => 1.5,
          'context'  => "This is a <mark>#{query}</mark> result",
          'document' => build(:document_data, id: 'search1', title: "Document with #{query}"),
        },
        {
          'ranking'  => 0.8,
          'context'  => "Another <mark>#{query}</mark> result",
          'document' => build(:document_data, id: 'search2', title: 'Another document'),
        },
      ]
    end
  end
end
