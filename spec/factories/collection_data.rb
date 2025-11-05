FactoryBot.define do
  factory :collection_data, class: Hash do
    skip_create

    id { 'col123' }
    name { 'Playbook' }
    description { "# Welcome to the Playbook\n\nThis is our company playbook." }
    url { "https://app.getoutline.com/collection/playbook-#{id}" }

    initialize_with { attributes.stringify_keys }
  end
end
