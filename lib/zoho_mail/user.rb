module ZohoMail
  # The organisation's users, which Zoho's API calls accounts.
  class User < Base
    include Addresses

    self.prefix = "/api/organization/:zoid/"
    self.element_name = "account"
    self.primary_key = "zuid"

    # Zoho's sample response for the list is one user, not an array.
    class List < ActiveResource::Collection
      def initialize(data = [])
        super(Array.wrap(data))
      end

      def admins
        select(&:admin?)
      end
    end

    self.collection_parser = List

    def add_alias(address)
      change("addEmailAlias", zuid: id, emailAlias: [ address ])
    end
  end
end
