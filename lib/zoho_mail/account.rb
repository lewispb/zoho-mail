module ZohoMail
  # The signed-in user's own mail accounts.
  class Account < Base
    include Addresses

    self.prefix = "/api/"
    self.primary_key = "accountId"

    # Zoho's sample response has the organisation ID inside policyId.
    def organization_id
      attributes["zoid"] || attributes["policyId"]&.zoid
    end

    # A number, such as 82; Zoho does not document what each number means.
    def plan_type
      attributes["planType"]
    end
  end
end
