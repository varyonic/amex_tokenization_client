require 'base64'
require 'openssl'
require "amex_tokenization_client/version"

class AmexTokenizationClient
  attr_reader :host
  attr_reader :client_id, :client_secret

  def initialize(host:, client_id:, client_secret:)
    @host = host
    @client_id, @client_secret = client_id, client_secret
  end

  # @param [String] method, e.g. 'POST'
  # @param [String] resource_path, e.g. '/payments/digital/v2/tokens/provisioning'
  # @param [String] JSON payload
  # @return [String] Authorization: MAC id="gfFb4K8esqZgMpzwF9SXzKLCCbPYV8bR",ts="1463772177193",nonce="61129a8d-ca24-464b-8891-9251501d86f0", bodyhash="YJpz6NdGP0aV6aYaa+6qKCjQt46of+Cj4liBz90G6X8=", mac="uzybzLPj3fD8eBZaBzb4E7pZs+l+IWS0w/w2wwsExdo="
  def hmac_authorization(method, resource_path, payload, nonce = SecureRandom.uuid, ts = (Time.now.to_r * 1000).to_i)
    bodyhash = hmac_digest(payload)
    mac = hmac_digest([ts, nonce, method, resource_path, host, 443, bodyhash, ''].join("\n"))
    %(MAC id="#{client_id}",ts="#{ts}",nonce="#{nonce}",bodyhash="#{bodyhash}",mac="#{mac}")
  end

  def hmac_digest(s)
    Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, client_secret, s))
  end
end
