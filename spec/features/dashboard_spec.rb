require 'rails_helper'

RSpec.feature 'Using the dashboard' do
  before do
    OmniAuth.config.add_mock(:mojsso, sso_response)
  end

  context 'log in and switch inbox' do
    let(:cardiff) { FactoryGirl.create(:estate, name: 'Cardiff') }
    let(:swansea) { FactoryGirl.create(:estate, name: 'Swansea') }
    let(:swansea_prison) { FactoryGirl.create(:prison, estate: swansea) }

    let(:sso_response) do
      {
        'uid' => '1234-1234-1234-1234',
        'provider' => 'mojsso',
        'info' => {
          'first_name' => 'Joe',
          'last_name' => 'Goldman',
          'email' => 'joe@example.com',
          'permissions' => [
            { 'organisation' => cardiff.sso_organisation_name, roles: [] },
            { 'organisation' => swansea.sso_organisation_name, roles: [] }
          ],
          'links' => {
            'profile' => 'http://example.com/profile',
            'logout' => 'http://example.com/logout'
          }
        }
      }
    end

    before do
      FactoryGirl.create(:visit, prison: swansea_prison)
    end

    xit do
      visit prison_inbox_path

      within '.prison-switcher' do
        select 'Cardiff', from: 'estate_id'
        click_button 'Update'
      end

      expect(page).to have_css('h1', text: 'Cardiff inbox')
      expect(page).to have_css('.navigation', 'Inbox 0')

      within '.prison-switcher' do
        select 'Swansea', from: 'estate_id'
        click_button 'Update'
      end

      expect(page).to have_css('h1', text: 'Swansea inbox')
      expect(page).to have_css('.navigation', 'Inbox 1')
    end
  end
end