# A small sinatra server used to fetch google oauth2 credentials

require "bundler/setup"
Bundler.require
require "dotenv/load"
require "google/api_client/client_secrets"
require "json"
require "sinatra"

creds_path = "./google_credentials.json"

puts "http://localhost:4567"

get "/" do
  redirect to("/oauth2callback") unless File.exist?(creds_path)

  creds = JSON.parse(File.read(creds_path))
  expires_at = Time.at(creds["expires_at"]).to_datetime
  remaining = ((expires_at - DateTime.now) * 1440).to_i

  redirect to("/oauth2refresh") if remaining < 0

  scope_items = creds["scope"].map { |s| "<li>#{s}</li>" }

  "
  <p>
  #{remaining} minutes remaining. <a href='/oauth2refresh'>Refresh now</a>.
  <ul>
  #{scope_items.join}
  </ul>
  </p>
  "
end

get "/oauth2refresh" do
  client_opts = JSON.parse(File.read(creds_path))
  auth_client = Signet::OAuth2::Client.new(client_opts)
  auth_client.refresh!
  File.write(creds_path, auth_client.to_json)
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
    File.write(creds_path, creds_json)

    redirect to("/")
  end
end
