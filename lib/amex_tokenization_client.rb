require 'base64'
require 'json'
require 'jwe'
require 'logger'
require 'openssl'
require "amex_tokenization_client/notifications_payload"
require "amex_tokenization_client/provisioning_payload"
require "amex_tokenization_client/request"
require "amex_tokenization_client/version"

class AmexTokenizationClient
  attr_reader :host
  attr_reader :base_path
  attr_reader :token_requester_id
  attr_reader :client_id, :client_secret
  attr_reader :encryption_key_id, :encryption_key
  attr_accessor :logger

  def initialize(host:,
                 token_requester_id:,
                 client_id:, client_secret:,
                 encryption_key_id:, encryption_key:,
                 logger: Logger.new('/dev/null'))
    @host = host
    @base_path = "/payments/digital/v2/tokens".freeze
    @token_requester_id = token_requester_id
    @client_id, @client_secret = client_id, client_secret
    @encryption_key_id, @encryption_key = encryption_key_id, Base64.decode64(encryption_key)
    @logger = logger
  end

  # @return [Hash] token_ref_id and other values.
  def provisioning(kargs)
    response = JSON.parse send_authorized_request('POST', 'provisioning', provisioning_payload(kargs))
    response.merge! JSON.parse jwe_decrypt response.delete('secure_token_data')
    response
  end

  def notifications(kargs)
    send_authorized_request('POST', 'notifications', notifications_payload(kargs))
  end

  def status(token_ref_id)
    JSON.parse send_authorized_request('GET', "#{token_ref_id}/status")
  end

  def metadata(token_ref_id)
    JSON.parse send_authorized_request('GET', "#{token_ref_id}/metadata")
  end

  def provisioning_payload(kargs)
    ProvisioningPayload.new(kargs).to_json(encryption_key_id, encryption_key)
  end

  def notifications_payload(kargs)
    NotificationsPayload.new(kargs).to_json(encryption_key_id, encryption_key)
  end

  def jwe_decrypt(data)
    JWE.decrypt(data, encryption_key)
  end

  def send_authorized_request(method, route, payload = nil)
    resource_path = "#{base_path}/#{route}"
    authorization = hmac_authorization(method, resource_path, payload)
    new_request(method, resource_path, authorization).send(payload)
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
    Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, client_secret, s.to_s))
  end

  def new_request(method, resource_path, authorization)
    Request.new(method, "https://#{host}/#{resource_path}", headers(authorization), logger: logger)
  end

  def headers(authorization)
    Hash[
      'Content-Type' => 'application/json',
      'Content-Language' => 'en-US',
      'x-amex-token-requester-id' => token_requester_id,
      'x-amex-api-key' => client_id,
      'x-amex-request-id' => SecureRandom.uuid,
      'authorization' => authorization,
    ]
  end
end
