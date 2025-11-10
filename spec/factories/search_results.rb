FactoryBot.define do
  factory :search_results, class: Array do
    skip_create

    transient do
      query { 'test' }
      count { 2 }
    end

    initialize_with do
      Array.new(count) do
        build(:search_result_data, query: query)
      end
    end
  end
end
