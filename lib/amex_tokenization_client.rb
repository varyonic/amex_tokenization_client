require 'base64'
require 'openssl'
require "amex_tokenization_client/version"

class AmexTokenizationClient
  attr_reader :client_secret

  def initialize(client_secret:)
    @client_secret = client_secret
  end

  def hmac_digest(s)
    Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, client_secret, s))
  end
end
