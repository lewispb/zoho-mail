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

  test "adding an alias domain changes the domain it points to" do
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.put "/api/organization/#{ORGANIZATION_ID}/domains/example.com", AUTHORIZATION, { status: { code: 200 } }.to_json
    end

    domains.first.add_alias("example.org")

    assert_equal "/api/organization/#{ORGANIZATION_ID}/domains/example.com", ActiveResource::HttpMock.requests.last.path
    assert_equal({ "mode" => "makeDomainAsAlias", "domainAlias" => "example.org" }, last_request_body)
  end

  test "DKIM keys of a domain" do
    primary_domain_key = domains.first.dkim_keys.sole

    assert_equal "zmail._domainkey", primary_domain_key.record_name
    assert_equal "v=DKIM1; k=rsa; p=TESTKEYEXAMPLECOM", primary_domain_key.public_key
    assert_predicate primary_domain_key, :verified?
    assert_predicate primary_domain_key, :default?
    assert_empty domains.pending.first.dkim_keys
  end

  test "adding a DKIM key returns the key Zoho generated" do
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.put "/api/organization/#{ORGANIZATION_ID}/domains/example.net", AUTHORIZATION, {
        status: { code: 200 },
        data: { dkimId: "1000000000000000023", selector: "zmail", isVerified: false, isDefault: false, publicKey: "v=DKIM1; k=rsa; p=TESTKEYEXAMPLENET" }
      }.to_json
    end
    added_domain = ZohoMail::Domain.create(zoid: ORGANIZATION_ID, domainName: "example.net")

    added_key = added_domain.add_dkim_key(selector: "zmail")

    assert_equal({ "mode" => "addDkimDetail", "selector" => "zmail", "keySize" => 2048, "isDefault" => true }, last_request_body)
    assert_equal "1000000000000000023", added_key.id
    assert_equal "v=DKIM1; k=rsa; p=TESTKEYEXAMPLENET", added_key.public_key
    assert_not added_key.verified?
  end

  test "verifying a DKIM key" do
    pending_domain = domains.pending.first

    pending_domain.verify_dkim_key(ZohoMail::DkimKey.new("dkimId" => "1000000000000000022"))

    assert_equal({ "mode" => "verifyDkimKey", "dkimId" => "1000000000000000022" }, last_request_body)
  end

  test "verifying MX and SPF records" do
    pending_domain = domains.pending.first

    pending_domain.verify_mx_records
    assert_equal({ "mode" => "verifyMxRecord" }, last_request_body)

    pending_domain.verify_spf_record
    assert_equal({ "mode" => "VerifySpfRecord" }, last_request_body)
  end

  private
    def domains
      ZohoMail::Domain.all(params: { zoid: ORGANIZATION_ID })
    end
end
