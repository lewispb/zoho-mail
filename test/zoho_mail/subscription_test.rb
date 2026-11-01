require "test_helper"

class ZohoMail::SubscriptionTest < ActiveSupport::TestCase
  test "finds the organisation's subscription" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/organization/#{ORGANIZATION_ID}/subscriptionInfo", AUTHORIZATION, fixture("subscription")
    end

    assert_equal "USD", ZohoMail::Subscription.find(params: { zoid: ORGANIZATION_ID }).currencyType
  end

  test "is served from the admin host" do
    assert_equal "mailadmin.zoho.com", ZohoMail::Subscription.site.host
  end
end
