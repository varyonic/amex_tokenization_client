RSpec.describe AmexTokenizationClient do
  it "has a version number" do
    expect(AmexTokenizationClient::VERSION).not_to be nil
  end

  let(:host) { 'api.qa.americanexpress.com' }
  let(:client_id) { ENV.fetch('AETS_CLIENT_ID') }
  let(:client_secret) { ENV.fetch('AETS_CLIENT_SECRET') }

  subject do
    AmexTokenizationClient.new(
      host: host,
      client_id: client_id,
      client_secret: client_secret
    )
  end

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
end
