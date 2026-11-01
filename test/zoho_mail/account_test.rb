require "test_helper"

class ZohoMail::AccountTest < ActiveSupport::TestCase
  setup do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/accounts", AUTHORIZATION, fixture("accounts")
    end
  end

  test "organisation ID comes from the account's policy" do
    assert_equal ORGANIZATION_ID, ZohoMail::Account.first.organization_id
  end

  test "ZohoMail.organization_id is the signed-in user's organisation" do
    assert_equal ORGANIZATION_ID, ZohoMail.organization_id
  end

  test "addresses, role and plan type" do
    super_admin_account = ZohoMail::Account.first

    assert_equal "admin@example.com", super_admin_account.email_address
    assert_equal [ "hello@example.com" ], super_admin_account.aliases
    assert_predicate super_admin_account, :admin?
    assert_equal 82, super_admin_account.plan_type
  end
end
