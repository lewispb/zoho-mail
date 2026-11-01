module ZohoMail
  # Accounts and users list their addresses as emailAddress:
  # [{"mailId": ..., "isPrimary": ..., "isAlias": ...}].
  module Addresses
    ADMIN_ROLES = %w[ super_admin admin ]

    def email_address
      attributes["primaryEmailAddress"]
    end

    def aliases
      Array.wrap(attributes["emailAddress"]).select(&:isAlias).map(&:mailId)
    end

    def admin?
      attributes["role"].in?(ADMIN_ROLES)
    end
  end
end
