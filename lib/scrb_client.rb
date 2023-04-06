require "httparty"
class ScrbClient
  include HTTParty

  base_uri "https://api.app.shortcut.com/api/v3"
  headers({
    "Content-Type": "application/json",
    "Shortcut-Token": ENV.fetch("SHORTCUT_API_TOKEN")
  })
end
