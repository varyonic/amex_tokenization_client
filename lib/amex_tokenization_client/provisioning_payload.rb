require 'json'

class AmexTokenizationClient
  class ProvisioningPayload
    attr_reader :account_number, :expiry_month, :expiry_year
    attr_reader :name, :email, :is_on_file, :ip_address

    def initialize(account_number:, name:, expiry_month:, expiry_year:, email:, is_on_file:, ip_address: nil)
      @account_number, @expiry_month, @expiry_year = account_number, expiry_month, expiry_year
      @name, @email, @is_on_file, @ip_address = name, email, is_on_file, ip_address
    end

    def to_json(encryption_key_id, encryption_key)
      Hash[
        account_data: account_data(encryption_key_id, encryption_key),
        user_data: { name: name, email: email },
        risk_assessment_data: risk_assessment_data
      ].to_json
    end

    protected

    def account_data(encryption_key_id, encryption_key)
       json = JSON.generate Hash[
        account_type: 'credit_card',
        credit_card: { account_number: account_number, expiry_month: expiry_month, expiry_year: expiry_year }
      ]
      jwe_encrypt(json, encryption_key_id, encryption_key)
    end

    def risk_assessment_data
      data = { account_input_method: is_on_file ? 'On File' : 'User Input' }
      data[:ip_address] = ip_address if ip_address
      data
    end

    def jwe_encrypt(data, encryption_key_id, encryption_key)
      JWE.encrypt(data, encryption_key, alg: 'A256KW', enc: 'A128GCM', kid: encryption_key_id)
    end
  end
end
