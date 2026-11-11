require 'spec_helper'

RSpec.describe 'Accessibility', type: :feature do
  before do
    outline_client = instance_double(OutlineClient)
    allow(OutlineClient).to receive(:new).and_return(outline_client)
    allow(outline_client).to receive(:get_collection)
      .and_return(build(:collection_data))
    allow(outline_client).to receive(:get_collection_structure)
      .and_return(build(:collection_structure))

    Capybara.app = Sinatra::Application
    Capybara.current_driver = :selenium_chrome_headless
    visit '/'
  end

  after do
    Capybara.use_default_driver
  end

  it 'has no WCAG 2.2 AA accessibility violations' do
    expect(page).to be_axe_clean.according_to(:wcag22aa)
  end
end
