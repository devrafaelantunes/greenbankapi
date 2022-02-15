import Config

config :green_bank_api, GreenBankApiWeb.Endpoint,
  url: [host: "localhost", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info
