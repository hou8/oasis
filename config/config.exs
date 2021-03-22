use Mix.Config

config :joken, access_token_secret_key: "secret"
config :joken, refresh_token_secret_key: "secret2"

config :oasis, :jwt,
  iss: "oasis_iss",
  aud: "oasis_aud",
  access_token_exp: 1,
  refresh_token_exp: 2
