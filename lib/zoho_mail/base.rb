module ZohoMail
  class Base < ActiveResource::Base
    self.site = "https://mail.#{ZohoMail.domain}"
    self.format = Format
    self.include_format_in_path = false
    self.include_root_in_json = false

    def self.headers
      super.merge("Authorization" => "Zoho-oauthtoken #{AccessToken.current}")
    end

    # Zoho makes most changes with a PUT to the resource's own URL that names
    # the change as "mode" in the body.
    def change(mode, **params)
      response = connection.put(element_path, self.class.format.encode({ mode: mode, **params }), self.class.headers)
      self.class.format.decode(response.body)
    end
  end
end
