defmodule Oasis.Gen.Plug.PreTestToken do
  # NOTICE: Please DO NOT write any business code in this module, since it will always be overwrote when
  # run the corresponding mix task command to the OpenAPI Specification.
  use Plug.Builder
  use Plug.ErrorHandler

  def call(conn, opts) do
    conn
    |> super(opts)
    |> Oasis.Plug.AccessTokenValidator.call(opts)
    |> Oasis.Gen.Plug.TestToken.call(opts)
    |> halt()
  end

  def handle_errors(conn, error) do
    Oasis.Gen.Plug.TestToken.handle_errors(conn, error)
  end
end
