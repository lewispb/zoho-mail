module ZohoMail
  # A Self Client registered in Zoho's API console, https://api-console.zoho.com.
  class OAuthClient
    REQUEST_TIMEOUT = 10.seconds

    def self.from_env
      new(id: ENV.fetch("ZOHO_CLIENT_ID"), secret: ENV.fetch("ZOHO_CLIENT_SECRET"))
    end

    def initialize(id:, secret:)
      @id = id
      @secret = secret
    end

    # The code is generated for the client in the API console and expires
    # after the duration chosen there.
    def refresh_token_for(code)
      request(grant_type: "authorization_code", code: code).fetch("refresh_token") do
        raise Error, "Zoho returned no refresh token for the code"
      end
    end

    def access_token_for(refresh_token)
      tokens = request(grant_type: "refresh_token", refresh_token: refresh_token)
      AccessToken.new(tokens.fetch("access_token"), tokens.fetch("expires_in").to_i.seconds.from_now)
    end

    private
      # Zoho answers a refused grant with status 200 and an "error" key.
      def request(params)
        response = post(params.merge(client_id: @id, client_secret: @secret))
        tokens = JSON.parse(response.body)

        if tokens["error"] || !response.is_a?(Net::HTTPSuccess)
          raise Error, "Zoho refused the token request: #{tokens["error"] || response.code}"
        end

        tokens
      end

      def post(params)
        uri = URI("https://accounts.#{ZohoMail.domain}/oauth/v2/token")

        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: REQUEST_TIMEOUT.to_i, read_timeout: REQUEST_TIMEOUT.to_i) do |http|
          http.post(uri.path, URI.encode_www_form(params), "Content-Type" => "application/x-www-form-urlencoded")
        end
      end
  end
end
