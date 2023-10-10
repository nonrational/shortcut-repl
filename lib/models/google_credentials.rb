class GoogleCredentials < Signet::OAuth2::Client
  class << self
    def json_path
      "./google_credentials.json"
    end

    def exist?
      File.exist?(json_path)
    end

    def load!
      raise "missing #{json_path}" unless exist?

      creds = new(JSON.parse(File.read(json_path)))

      if creds.expired?
        creds.refresh!
        creds.store!
        # G.O.A.T. – Google OAuth Access Token
        puts "✨🐐✨ valid until #{creds.expires_at.iso8601}"
      end

      creds
    end
  end

  def minutes_remaining
    ((expires_at - Time.now) / 60).to_i
  end

  def expired?
    minutes_remaining < 0
  end

  def store!
    File.write(singleton_class.json_path, to_json)
  end
end
