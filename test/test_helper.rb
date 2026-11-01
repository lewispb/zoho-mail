ENV["ZOHO_CLIENT_ID"] = "1000.TESTCLIENTID"
ENV["ZOHO_CLIENT_SECRET"] = "test-client-secret"
ENV["ZOHO_REFRESH_TOKEN"] = "test-refresh-token"
ENV.delete("ZOHO_DOMAIN")

require "bundler/setup"
require_relative "../lib/zoho_mail"
require "active_support/test_case"
require "minitest/autorun"
require "mocha/minitest"
require "webmock/minitest"
require "fileutils"
require "stringio"

# After Active Resource, whose Connection#http it replaces.
require "active_resource/http_mock"

class ActiveSupport::TestCase
  AUTHORIZATION = { "Authorization" => "Zoho-oauthtoken test-access-token" }
  ORGANIZATION_ID = 1000001

  setup do
    ZohoMail::AccessToken.stubs(:current).returns("test-access-token")
  end

  private
    def fixture(name)
      File.read(File.expand_path("fixtures/#{name}.json", __dir__))
    end

    def last_request_body
      JSON.parse(ActiveResource::HttpMock.requests.last.body)
    end
end
