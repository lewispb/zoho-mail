require "test_helper"

class ZohoMail::CLITest < ActiveSupport::TestCase
  setup do
    @output = StringIO.new
    @cli = ZohoMail::CLI.new(output: @output)

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/accounts", AUTHORIZATION, fixture("accounts")
      mock.get "/api/organization/#{ORGANIZATION_ID}/domains", AUTHORIZATION, fixture("domains_verified_and_pending")
      mock.get "/api/organization/#{ORGANIZATION_ID}/accounts?limit=100", AUTHORIZATION, fixture("users_as_array")
    end
  end

  test "account" do
    assert @cli.run([ "account" ])
    assert_equal <<~TEXT, @output.string
      admin@example.com
        role: super_admin
        organisation ID: #{ORGANIZATION_ID}
        plan type: 82
    TEXT
  end

  test "domains" do
    assert @cli.run([ "domains" ])
    assert_equal <<~TEXT, @output.string
      example.com  verified  primary  hosting  MX enabled
      example.org  MX expired
    TEXT
  end

  test "users" do
    assert @cli.run([ "users" ])
    assert_equal <<~TEXT, @output.string
      admin@example.com  super_admin  alias hello@example.com
      member@example.com  member
    TEXT
  end

  test "login prints the refresh token for the code" do
    ZohoMail::OAuthClient.any_instance.expects(:refresh_token_for).with("1000.grant").returns("new-refresh-token")

    assert @cli.run([ "login", "1000.grant" ])
    assert_equal "new-refresh-token\n", @output.string
  end

  test "login without a code" do
    assert_raises(ZohoMail::Error) { @cli.run([ "login" ]) }
  end

  test "an unknown command prints the usage" do
    assert_not @cli.run([ "unknown" ])
    assert_match "usage: zoho-mail", @output.string
  end
end
