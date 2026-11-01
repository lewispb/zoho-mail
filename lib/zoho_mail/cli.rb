module ZohoMail
  class CLI
    USAGE = <<~TEXT
      usage: zoho-mail <command>

        login CODE     exchange a Self Client grant code and print the refresh token
        account        your account: its address, role, organisation ID and plan type
        subscription   the organisation's plan, add-ons and expiry date
        domains        the organisation's domains and their status
        users          the organisation's users and their addresses
        console        an IRB session with the ZohoMail models loaded
    TEXT

    def initialize(output: $stdout)
      @output = output
    end

    def run(arguments)
      command, *parameters = arguments

      case command
      when "login" then login(*parameters)
      when "account" then account
      when "subscription" then subscription
      when "domains" then domains
      when "users" then users
      when "console" then console
      else
        @output.puts USAGE
        return false
      end

      true
    end

    private
      def login(code = nil)
        raise Error, "usage: zoho-mail login CODE" unless code
        @output.puts OAuthClient.from_env.refresh_token_for(code)
      end

      def account
        Account.all.each do |account|
          @output.puts account.email_address
          @output.puts "  role: #{account.attributes["role"]}"
          @output.puts "  organisation ID: #{account.organization_id}"
          @output.puts "  plan type: #{account.plan_type}"
        end
      end

      def subscription
        @output.puts JSON.pretty_generate(Subscription.find(params: { zoid: ZohoMail.organization_id }).serializable_hash)
      end

      def domains
        Domain.all(params: { zoid: ZohoMail.organization_id }).each do |domain|
          @output.puts [ domain.name, *domain_states(domain), "MX #{domain.mx_status}" ].join("  ")
        end
      end

      def domain_states(domain)
        { "verified" => domain.verified?, "primary" => domain.primary?, "alias" => domain.alias?, "hosting" => domain.mail_hosting? }
          .filter_map { |state, applies| state if applies }
      end

      def users
        User.all(params: { zoid: ZohoMail.organization_id, limit: 100 }).each do |user|
          @output.puts [ user.email_address, user.attributes["role"], *user.aliases.map { |address| "alias #{address}" } ].join("  ")
        end
      end

      # IRB reads ARGV as a script to run.
      def console
        require "irb"
        ARGV.clear
        IRB.start
      end
  end
end
