RSpec.describe AmexTokenizationClient do
  it "has a version number" do
    expect(AmexTokenizationClient::VERSION).not_to be nil
  end

  let(:host) { 'api.qa.americanexpress.com' }
  let(:token_requester_id) { ENV.fetch('AETS_TOKEN_REQUESTER_ID')}
  let(:client_id) { ENV.fetch('AETS_CLIENT_ID') }
  let(:client_secret) { ENV.fetch('AETS_CLIENT_SECRET') }
  let(:encryption_key_id) { ENV.fetch('AETS_ENC_KEY_ID') }
  let(:encryption_key) { ENV.fetch('AETS_ENC_KEY') }
  let(:account_params) do
    {
      account_number: "371111111111111",
      name: "first|middle|last",
      expiry_month: 2,
      expiry_year: 2020,
      email: "emailId@github.com",
      is_on_file: true
    }
  end

  subject do
    AmexTokenizationClient.new(
      host: host,
      token_requester_id: token_requester_id,
      client_id: client_id,
      client_secret: client_secret,
      encryption_key_id: encryption_key_id,
      encryption_key: encryption_key,
    )
  end

  before { subject.logger = Logger.new(STDOUT) if ENV['AETS_LOG'] }

  context do
    # Copied from amex-api-java-client-core ApiAuthenticationTest.java
    let(:host) { 'github.com' }
    let(:client_id) { "UNIT-TEST-KEY-4388-87b9-85cf463231d7" }
    let(:client_secret) { 'UNIT-TEST-SEC-4206-8a21-a73eed54c896' }
    let(:payload) { 'The swift brown fox jumped over the lazy dogs back' }
    let(:bodyhash) { 'wlAalPXGd1oDuqepWDawftGy9zhgEV3oHZve/hz5Yac=' }

    it 'digests a payload' do
      expect(subject.hmac_digest(payload)).to eq(bodyhash)
    end

    context do
      let(:resource_path) { "/americanexpress/risk/fraud/v1/enhanced_authorizations/online_purchases" }
      let(:nonce) { "f00870f3-5862-45f1-9bd1-ba94c71d2661"}
      let(:ts) { "1473803713478" }

      it 'generates an HMAC header value' do
        authorization = subject.hmac_authorization('POST', resource_path, payload, nonce, ts)
        expect(authorization).to match(%Q{MAC id="#{client_id}"})
        expect(authorization).to match(%Q{,ts="#{ts}"})
        expect(authorization).to match(%Q{,nonce="#{nonce}"})
        expect(authorization).to match(%Q{,bodyhash="#{bodyhash}"})
      end
    end
  end

  it 'provisions a token' do
    token = subject.provisioning(account_params)
    expect(token.keys).to include('token_ref_id')
    expect(token.fetch('token_number')).to match(/\d{12,19}/)
    expect(token.fetch('expiry_month').to_s).to match(/\d{1,2}/)
    expect(token.fetch('expiry_year').to_s).to match(/20\d{1,2}/)

    subject.notifications(token_ref_id: token['token_ref_id'], notification_type: :suspend)

    status = subject.status(token['token_ref_id'])
    expect(status.keys).to include('token_status')

    metadata = subject.metadata(token['token_ref_id'])
    expect(metadata.keys).to include('token_metadata')
  end

  it 'returns error details' do
    expect do
      account_params[:email] = "emailId@yahoo.com.mx"
      subject.provisioning(account_params)
    end.to raise_error(AmexTokenizationClient::Request::UnexpectedHttpResponse, /Bad Request \(400\): {"error_code":"104000","error_type":"invalid_email","error_description":"invalid_request_error"}/)
  end
end
