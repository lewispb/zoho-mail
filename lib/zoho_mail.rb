require "active_resource"
require "active_support/core_ext/array/wrap"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/object/inclusion"
require "digest"
require "json"
require "net/http"
require "tmpdir"

module ZohoMail
  Error = Class.new(StandardError)

  class << self
    # Each Zoho data centre has its own domain: zoho.com, zoho.eu, zoho.in,
    # zoho.com.au, zoho.jp, zohocloud.ca and others.
    def domain
      ENV.fetch("ZOHO_DOMAIN", "zoho.com")
    end

    def organization_id
      Account.first.organization_id
    end
  end
end

require_relative "zoho_mail/oauth_client"
require_relative "zoho_mail/access_token"
require_relative "zoho_mail/format"
require_relative "zoho_mail/base"
require_relative "zoho_mail/addresses"
require_relative "zoho_mail/account"
require_relative "zoho_mail/domain"
require_relative "zoho_mail/user"
require_relative "zoho_mail/subscription"
require_relative "zoho_mail/cli"
