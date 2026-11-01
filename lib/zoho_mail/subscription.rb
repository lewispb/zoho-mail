module ZohoMail
  # The organisation's plan, add-ons and expiry date.
  class Subscription < Base
    include ActiveResource::Singleton

    self.site = "https://mailadmin.#{ZohoMail.domain}"
    self.prefix = "/api/organization/:zoid/"
    self.singleton_name = "subscriptionInfo"
  end
end
