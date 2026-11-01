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

    # Zoho answers 200 when it refuses an address too, with an errorCode next
    # to it, such as EMAILADDRESS_ALREADY_EXISTS while a deleted user's
    # address is still held.
    def add_alias(address)
      results = Array.wrap(change("addEmailAlias", zuid: id, emailAlias: [ address ]))

      if refusal = results.find { |result| result["errorCode"] }
        raise Error, "Zoho did not add #{address}: #{refusal["errorCode"]}"
      end

      results
    end

    # Deletes the user and their mail. Zoho takes a DELETE to the list of
    # users with their IDs in the body, which Active Resource cannot send.
    def destroy
      uri = URI.join(self.class.site.to_s, self.class.collection_path(prefix_options))
      request = Net::HTTP::Delete.new(uri, self.class.headers.merge("Accept" => "application/json", "Content-Type" => "application/json"))
      request.body = { accountList: [ id ] }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
      raise Error, "Zoho did not delete #{email_address}: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
      Format.decode(response.body)
    end
  end
end
