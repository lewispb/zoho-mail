require "test_helper"

class ZohoMail::UserTest < ActiveSupport::TestCase
  test "lists users from an array" do
    respond_with_users fixture("users_as_array")

    assert_equal %w[ admin@example.com member@example.com ], users.map(&:email_address)
  end

  test "lists a single user returned as an object" do
    respond_with_users fixture("users_as_single_object")

    assert_equal %w[ member@example.com ], users.map(&:email_address)
  end

  test "admins" do
    respond_with_users fixture("users_as_array")

    assert_equal %w[ admin@example.com ], users.admins.map(&:email_address)
  end

  test "aliases leave out the primary address" do
    respond_with_users fixture("users_as_array")

    assert_equal %w[ hello@example.com ], users.first.aliases
    assert_empty users.last.aliases
  end

  test "adding an alias" do
    respond_with_users fixture("users_as_array")
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.put "/api/organization/#{ORGANIZATION_ID}/accounts/2000002", AUTHORIZATION, { status: { code: 200 }, data: {} }.to_json
    end

    users.last.add_alias("info@example.com")

    assert_equal({ "mode" => "addEmailAlias", "zuid" => 2000002, "emailAlias" => [ "info@example.com" ] }, last_request_body)
  end

  private
    def respond_with_users(response_body)
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/organization/#{ORGANIZATION_ID}/accounts?limit=100", AUTHORIZATION, response_body
      end
    end

    def users
      ZohoMail::User.all(params: { zoid: ORGANIZATION_ID, limit: 100 })
    end
end
