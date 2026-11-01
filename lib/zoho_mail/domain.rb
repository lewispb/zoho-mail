module ZohoMail
  class Domain < Base
    DKIM_KEY_SIZE = 2048

    self.prefix = "/api/organization/:zoid/"
    self.primary_key = "domainName"

    class List < ActiveResource::Collection
      def initialize(data = {})
        super(data["domainVO"])
      end

      def pending
        reject(&:verified?)
      end
    end

    self.collection_parser = List

    def name
      attributes["domainName"]
    end

    def verified?
      attributes["verificationStatus"] == true
    end

    def primary?
      attributes["primary"] == true
    end

    def alias?
      attributes["isDomainAlias"] == true
    end

    def mail_hosting?
      attributes["mailHostingEnabled"] == true
    end

    # Zoho's check of the domain's MX records, such as "expired".
    def mx_status
      attributes["mxstatus"]
    end

    # Zoho checks the TXT record named by txt_verification_record.
    def verify
      change("verifyDomainByTXT")
    end

    def txt_verification_record
      "zoho-verification=#{attributes["CNAMEVerificationCode"]}.zmverify.#{ZohoMail.domain}"
    end

    def enable_mail_hosting
      change("enableMailHosting")
    end

    # Every user of this domain gets the same address at the alias domain,
    # which Zoho must have verified first.
    def add_alias(alias_domain_name)
      change("makeDomainAsAlias", domainAlias: alias_domain_name)
    end

    def dkim_keys
      Array.wrap(attributes["dkimDetailList"]).map { |detail| DkimKey.new(detail.attributes) }
    end

    # Zoho generates the key pair; publish the public key at the key's
    # record_name before verifying it.
    def add_dkim_key(selector:, key_size: DKIM_KEY_SIZE)
      DkimKey.new(change("addDkimDetail", selector: selector, keySize: key_size, isDefault: true))
    end

    def verify_dkim_key(dkim_key)
      change("verifyDkimKey", dkimId: dkim_key.id)
    end

    def verify_mx_records
      change("verifyMxRecord")
    end

    def verify_spf_record
      change("verifySpfRecord")
    end
  end
end
