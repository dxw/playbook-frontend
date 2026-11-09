class Authentication
  def self.signed_in?(session)
    session[:user_email].is_a?(String) && !session[:user_email].empty?
  end

  # Google Workspace only sends an email attribute if one is mapped in the SAML app,
  # but always sends the primary email as the NameID, which OmniAuth exposes as the uid.
  def self.email(auth_hash)
    email = auth_hash.dig('info', 'email')
    email = auth_hash['uid'] unless email.is_a?(String) && !email.empty?

    email if email.is_a?(String) && !email.empty?
  end

  def self.dxw_user?(auth_hash)
    email = email(auth_hash)

    !email.nil? && email.downcase.end_with?('@dxw.com')
  end

  def self.sign_in(session, auth_hash)
    session[:user_email] = email(auth_hash) if dxw_user?(auth_hash)
  end

  # Only allow local paths so the SAML RelayState can't be used as an open redirect.
  SAFE_RETURN_PATH = %r{\A/(?![/\\])[^\x00-\x20\x7f\\]*\z}

  def self.return_path(path)
    return '/' unless path.is_a?(String) && path.match?(SAFE_RETURN_PATH)
    return '/' if path.start_with?('/auth/')

    path
  end

  def self.sign_out(session)
    session.delete(:user_email)
  end
end
