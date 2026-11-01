module ZohoMail
  class Domain < Base
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
  end
end
