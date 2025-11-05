FactoryBot.define do
  factory :search_result_data, class: Hash do
    skip_create

    ranking { 1.5 }
    context { "This is a <mark>test</mark> result" }
    association :document, factory: :document_data, strategy: :build

    initialize_with do
      attrs = attributes.stringify_keys
      attrs['document'] = document
      attrs
    end

    trait :secondary do
      ranking { 0.8 }
      context { "Another <mark>test</mark> result" }
      document { build(:document_data, id: 'search2', title: 'Another document') }
    end
  end
end
