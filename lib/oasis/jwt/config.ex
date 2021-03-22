defmodule Oasis.Jwt.Config do
  @config Application.get_env(:oasis, :jwt, [])

  def iss, do: Keyword.get(@config, :iss, "oasis")
  def aud, do: Keyword.get(@config, :aud, "oasis")

  # default 30 min
  def access_token_exp, do: Keyword.get(@config, :access_token_exp, 30 * 60)

  # default 3 day
  def refresh_token_exp, do: Keyword.get(@config, :refresh_token_exp, 3 * 24 * 60 * 60)
end
