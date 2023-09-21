class GoogleCredentials < Signet::OAuth2::Client
  class << self
    def json_path
      "./google_credentials.json"
    end

    def exist?
      File.exist?(json_path)
    end

    def load!
      raise unless exist?

      new(JSON.parse(File.read(json_path))).tap do |creds|
        if creds.expired?
          creds.refresh!
          creds.store!
        end

        puts "Token valid for #{creds.minutes_remaining} minutes"
      end
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
