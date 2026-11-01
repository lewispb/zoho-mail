module ZohoMail
  # Zoho wraps every response body as {"status": {...}, "data": ...}.
  module Format
    extend self

    def extension = "json"
    def mime_type = "application/json"
    def encode(hash, options = nil) = ActiveSupport::JSON.encode(hash, options)
    def decode(json) = json.blank? ? nil : ActiveSupport::JSON.decode(json)["data"]
  end
end
