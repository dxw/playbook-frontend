class Authentication
  def self.signed_in?(session)
    session[:user_email].is_a?(String) && !session[:user_email].empty?
  end

  def self.dxw_user?(auth_hash)
    email = auth_hash.dig('info', 'email')

    email.is_a?(String) && email.downcase.end_with?('@dxw.com')
  end

  def self.sign_in(session, auth_hash)
    session[:user_email] = auth_hash.dig('info', 'email') if dxw_user?(auth_hash)
  end

  def self.sign_out(session)
    session.delete(:user_email)
  end
end
