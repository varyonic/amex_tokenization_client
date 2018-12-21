RSpec.describe AmexTokenizationClient do
  it "has a version number" do
    expect(AmexTokenizationClient::VERSION).not_to be nil
  end

  let(:client_secret) { ENV.fetch('AETS_CLIENT_SECRET') }
  subject do
    AmexTokenizationClient.new(
      client_secret: client_secret
    )
  end

  context do
    let(:client_secret) { 'UNIT-TEST-SEC-4206-8a21-a73eed54c896' }
    let(:payload) { 'The swift brown fox jumped over the lazy dogs back' }
    let(:bodyhash) { 'wlAalPXGd1oDuqepWDawftGy9zhgEV3oHZve/hz5Yac=' }

    it 'digests a payload' do
      expect(subject.hmac_digest(payload)).to eq(bodyhash)
    end
  end
end
