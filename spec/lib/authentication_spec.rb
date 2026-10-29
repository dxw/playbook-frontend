require 'spec_helper'

RSpec.describe Authentication do
  let(:session) { {} }
  let(:auth_hash) { { 'info' => { 'email' => 'person@dxw.com' } } }

  describe '.signed_in?' do
    it 'returns true when the session has a user email' do
      session[:user_email] = 'person@dxw.com'

      expect(Authentication.signed_in?(session)).to be(true)
    end

    it 'returns false when the session does not have a user email' do
      expect(Authentication.signed_in?(session)).to be(false)
    end
  end

  describe '.dxw_user?' do
    it 'accepts a dxw email address from a SAML assertion' do
      expect(Authentication.dxw_user?(auth_hash)).to be(true)
    end

    it 'rejects an email address outside dxw' do
      auth_hash['info']['email'] = 'person@example.com'

      expect(Authentication.dxw_user?(auth_hash)).to be(false)
    end
  end

  describe '.sign_in' do
    it 'stores the email address for a dxw SAML user' do
      Authentication.sign_in(session, auth_hash)

      expect(session[:user_email]).to eq('person@dxw.com')
    end

    it 'does not store an email address for an unauthorised user' do
      auth_hash['info']['email'] = 'person@example.com'

      Authentication.sign_in(session, auth_hash)

      expect(session).not_to have_key(:user_email)
    end
  end

  describe '.sign_out' do
    it 'removes the signed-in user from the session' do
      session[:user_email] = 'person@dxw.com'

      Authentication.sign_out(session)

      expect(Authentication.signed_in?(session)).to be(false)
    end
  end
end
