FactoryBot.define do
  factory :collection_structure, class: Array do
    skip_create

    initialize_with do
      [
        {
          'id'       => 'doc1',
          'title'    => 'Introduction',
          'url'      => '/doc/introduction-doc1',
          'children' => [
            {
              'id'       => 'doc2',
              'title'    => 'Getting Started',
              'url'      => '/doc/getting-started-doc2',
              'children' => [],
            },
          ],
        },
        {
          'id'       => 'doc3',
          'title'    => 'Guidelines',
          'url'      => '/doc/guidelines-doc3',
          'children' => [],
        },
      ]
    end
  end
end
