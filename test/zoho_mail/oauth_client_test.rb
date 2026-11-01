require "test_helper"

class ZohoMail::OAuthClientTest < ActiveSupport::TestCase
  setup do
    @self_client = ZohoMail::OAuthClient.new(id: "1000.TESTCLIENTID", secret: "test-client-secret")
  end

  test "exchanges a grant code for a refresh token" do
    stub_token_request(grant_type: "authorization_code", code: "1000.grant")
      .to_return(body: { access_token: "new-access-token", refresh_token: "new-refresh-token", expires_in: 3600 }.to_json)

    assert_equal "new-refresh-token", @self_client.refresh_token_for("1000.grant")
  end

  test "raises when Zoho refuses the code" do
    stub_token_request(grant_type: "authorization_code", code: "1000.expired")
      .to_return(body: { error: "invalid_code" }.to_json)

    error = assert_raises(ZohoMail::Error) { @self_client.refresh_token_for("1000.expired") }
    assert_match "invalid_code", error.message
  end

  test "an access token expires after the lifetime Zoho gives it" do
    freeze_time do
      stub_token_request(grant_type: "refresh_token", refresh_token: "test-refresh-token")
        .to_return(body: { access_token: "new-access-token", expires_in: 3600 }.to_json)

      access_token = @self_client.access_token_for("test-refresh-token")

      assert_equal "new-access-token", access_token.value
      assert_equal 1.hour.from_now, access_token.expires_at
    end
  end

  test "uses the accounts server of the data centre in ZOHO_DOMAIN" do
    ZohoMail.stubs(:domain).returns("zoho.eu")
    stub_token_request(grant_type: "authorization_code", code: "1000.grant", host: "accounts.zoho.eu")
      .to_return(body: { refresh_token: "new-refresh-token" }.to_json)

    assert_equal "new-refresh-token", @self_client.refresh_token_for("1000.grant")
  end

  private
    def stub_token_request(host: "accounts.zoho.com", **params)
      stub_request(:post, "https://#{host}/oauth/v2/token")
        .with(body: params.merge(client_id: "1000.TESTCLIENTID", client_secret: "test-client-secret"))
    end
end
