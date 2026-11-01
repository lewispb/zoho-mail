module ZohoMail
  class Base < ActiveResource::Base
    self.site = "https://mail.#{ZohoMail.domain}"
    self.format = Format
    self.include_format_in_path = false
    self.include_root_in_json = false

    def self.headers
      super.merge("Authorization" => "Zoho-oauthtoken #{AccessToken.current}")
    end

    # Active Resource takes the prefix options, such as the organisation's
    # zoid, from each response it loads, and Zoho's responses often leave them
    # out. Keep the ones the record already has.
    def load(attributes, remove_root = false, persisted = false)
      prefix_options = @prefix_options
      super.tap { @prefix_options = prefix_options.merge(@prefix_options) if prefix_options }
    end

    # Zoho makes most changes with a PUT to the resource's own URL that names
    # the change as "mode" in the body.
    def change(mode, **params)
      response = connection.put(element_path, self.class.format.encode({ mode: mode, **params }), self.class.headers)
      self.class.format.decode(response.body)
    end
  end
end
