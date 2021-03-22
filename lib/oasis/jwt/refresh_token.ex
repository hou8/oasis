defmodule Oasis.Jwt.RefreshToken do
  require Logger
  import Oasis.Jwt.Config

  use Joken.Config,
    default_signer: :access_token_secret_key

  @impl true
  def token_config do
    [iss: iss(), aud: aud(), default_exp: refresh_token_exp()]
    |> default_claims()
  end
end
