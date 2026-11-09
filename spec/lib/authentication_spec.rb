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

    it 'accepts a dxw email address from the SAML NameID when no email attribute is sent' do
      expect(Authentication.dxw_user?({ 'uid' => 'person@dxw.com', 'info' => { 'email' => nil } })).to be(true)
    end

    it 'rejects a NameID outside dxw when no email attribute is sent' do
      expect(Authentication.dxw_user?({ 'uid' => 'person@example.com', 'info' => { 'email' => nil } })).to be(false)
    end

    it 'rejects an assertion without an email attribute or NameID' do
      expect(Authentication.dxw_user?({ 'info' => {} })).to be(false)
    end
  end

  describe '.sign_in' do
    it 'stores the email address for a dxw SAML user' do
      Authentication.sign_in(session, auth_hash)

      expect(session[:user_email]).to eq('person@dxw.com')
    end

    it 'stores the NameID email address when no email attribute is sent' do
      Authentication.sign_in(session, { 'uid' => 'person@dxw.com', 'info' => { 'email' => nil } })

      expect(session[:user_email]).to eq('person@dxw.com')
    end

    it 'does not store an email address for an unauthorised user' do
      auth_hash['info']['email'] = 'person@example.com'

      Authentication.sign_in(session, auth_hash)

      expect(session).not_to have_key(:user_email)
    end
  end

  describe '.return_path' do
    it 'returns a local path with a query string' do
      expect(Authentication.return_path('/search?query=private')).to eq('/search?query=private')
    end

    it 'returns a local document path' do
      expect(Authentication.return_path('/doc/private123')).to eq('/doc/private123')
    end

    [
      nil,
      '',
      'https://evil.example.com',
      '//evil.example.com',
      '/\\evil.example.com',
      "/\t/evil.example.com",
      "/doc\r\nSet-Cookie: x=y",
      'javascript:alert(1)',
      '/auth/failure',
    ].each do |path|
      it "falls back to the home page for #{path.inspect}" do
        expect(Authentication.return_path(path)).to eq('/')
      end
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
