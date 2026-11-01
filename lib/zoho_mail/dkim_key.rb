module ZohoMail
  class DkimKey
    attr_reader :id, :selector, :public_key

    def initialize(attributes)
      @id = attributes["dkimId"]
      @selector = attributes["selector"]
      @public_key = attributes["publicKey"]
      @verified = attributes["isVerified"] == true
      @default = attributes["isDefault"] == true
    end

    def verified?
      @verified
    end

    def default?
      @default
    end

    # The name of the TXT record that publishes the public key, relative to the
    # domain.
    def record_name
      "#{selector}._domainkey"
    end
  end
end
