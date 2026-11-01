module ZohoMail
  # Zoho limits how many access tokens a refresh token can issue in ten
  # minutes, so each one is kept until it expires in $XDG_RUNTIME_DIR, which is
  # in memory and readable by this user only.
  class AccessToken
    EXPIRY_MARGIN = 1.minute

    attr_reader :value, :expires_at

    class << self
      def current(refresh_token = ENV.fetch("ZOHO_REFRESH_TOKEN"))
        cached(refresh_token) || OAuthClient.from_env.access_token_for(refresh_token).tap { |token| token.cache(refresh_token) }
      end

      # Named after a digest of the refresh token, so that each Zoho account
      # has its own file and the file name gives nothing away.
      def cache_path(refresh_token)
        File.join(ENV.fetch("XDG_RUNTIME_DIR", Dir.tmpdir), "zoho-mail-#{Digest::SHA256.hexdigest(refresh_token)[0, 16]}.json")
      end

      private
        def cached(refresh_token)
          path = cache_path(refresh_token)

          if File.exist?(path)
            stored = JSON.parse(File.read(path))
            token = new(stored.fetch("value"), Time.at(stored.fetch("expires_at")))
            token unless token.expired?
          end
        end
    end

    def initialize(value, expires_at)
      @value = value
      @expires_at = expires_at
    end

    def expired?(at = Time.now)
      expires_at <= EXPIRY_MARGIN.since(at)
    end

    def cache(refresh_token)
      File.open(self.class.cache_path(refresh_token), File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
        file.write({ value: value, expires_at: expires_at.to_i }.to_json)
      end
    end

    def to_s
      value
    end
  end
end
