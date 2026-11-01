require "test_helper"

class ZohoMail::DomainTest < ActiveSupport::TestCase
  setup do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/organization/#{ORGANIZATION_ID}/domains", AUTHORIZATION, fixture("domains_verified_and_pending")
      mock.post "/api/organization/#{ORGANIZATION_ID}/domains", AUTHORIZATION, fixture("domain_added"), 201
      mock.put "/api/organization/#{ORGANIZATION_ID}/domains/example.org", AUTHORIZATION, { status: { code: 200 }, data: {} }.to_json
    end
  end

  test "lists the organisation's domains" do
    assert_equal %w[ example.com example.org ], domains.map(&:name)
  end

  test "pending domains are the ones Zoho has not verified" do
    assert_equal %w[ example.org ], domains.pending.map(&:name)
  end

  test "states of a verified primary domain" do
    primary_domain = domains.first

    assert_predicate primary_domain, :verified?
    assert_predicate primary_domain, :primary?
    assert_predicate primary_domain, :mail_hosting?
    assert_not primary_domain.alias?
    assert_equal "enabled", primary_domain.mx_status
  end

  test "adding a domain sends its name, with the organisation in the path" do
    added_domain = ZohoMail::Domain.create(zoid: ORGANIZATION_ID, domainName: "example.net")

    assert_equal({ "domainName" => "example.net" }, last_request_body)
    assert_equal "example.net", added_domain.name
    assert_not added_domain.verified?
  end

  test "the TXT record that verifies a domain" do
    added_domain = ZohoMail::Domain.create(zoid: ORGANIZATION_ID, domainName: "example.net")

    assert_equal "zoho-verification=zb10000013.zmverify.zoho.com", added_domain.txt_verification_record
  end

  test "verify asks Zoho to check the TXT record" do
    domains.pending.first.verify

    assert_equal :put, ActiveResource::HttpMock.requests.last.method
    assert_equal({ "mode" => "verifyDomainByTXT" }, last_request_body)
  end

  test "enable mail hosting" do
    domains.pending.first.enable_mail_hosting

    assert_equal({ "mode" => "enableMailHosting" }, last_request_body)
  end

  private
    def domains
      ZohoMail::Domain.all(params: { zoid: ORGANIZATION_ID })
    end
end
