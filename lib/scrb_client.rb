require "httparty"

class ScrbClient
  include HTTParty

  base_uri "https://api.app.shortcut.com/api/v3"
  headers({
    "Content-Type": "application/json",
    "Shortcut-Token": Scrb.api_key
  })
end
