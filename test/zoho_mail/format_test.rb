require "test_helper"

class ZohoMail::FormatTest < ActiveSupport::TestCase
  test "decode returns the data inside Zoho's response" do
    response_body = { status: { code: 200, description: "success" }, data: { domainName: "example.com" } }.to_json

    assert_equal({ "domainName" => "example.com" }, ZohoMail::Format.decode(response_body))
  end

  test "decode returns nil for an empty body" do
    assert_nil ZohoMail::Format.decode("")
  end
end
