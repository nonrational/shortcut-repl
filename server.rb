# A small sinatra server used to fetch google oauth2 credentials

require "bundler/setup"
Bundler.require
require "dotenv/load"
require "google/api_client/client_secrets"
require "json"
require "sinatra"
require_relative "./lib/models/google_credentials"

get "/" do
  redirect to("/oauth2callback") unless GoogleCredentials.exist?

  creds = GoogleCredentials.load!

  redirect to("/oauth2refresh") if creds.expired?

  "
  <p>
  #{creds.minutes_remaining} minutes remaining. <a href='/oauth2refresh'>Refresh now</a>.
  </p>
  <p>
  Granted scopes:
  <ul>
  #{creds.granted_scopes.map { |s| "<li>#{s}</li>" }.join}
  </ul>
  </p>
  "
end

get "/oauth2refresh" do
  GoogleCredentials.load!.tap(&:refresh!).tap(&:store!)
  redirect to("/")
end

get "/oauth2callback" do
  client_secrets = Google::APIClient::ClientSecrets.load("./client_secrets.json")
  auth_client = client_secrets.to_authorization

  auth_client.update!(
    scope: "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/spreadsheets",
    redirect_uri: url("/oauth2callback")
  )

  if request["code"].nil?
    auth_uri = auth_client.authorization_uri.to_s
    redirect to(auth_uri)
  else
    auth_client.code = request["code"]
    auth_client.fetch_access_token!
    creds_json = auth_client.to_json

    session[:credentials] = creds_json
    File.write(GoogleCredentials.json_path, creds_json)

    redirect to("/")
  end
end
