defmodule Oasis.Plug.AccessTokenValidator do
  @moduledoc """
  JWT plug to handle the JWT bearer token
  """

  import Plug.Conn
  require Logger
  alias Oasis.Jwt.AccessToken

  @behaviour Plug

  @spec init(keyword()) :: keyword()
  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        verify_token(conn, token)

      v ->
        Logger.warn(fn ->
          "Expected a bearer token in the 'authorization' header. Got #{inspect(v)}"
        end)

        send_401(conn, "invalid_token_format")
    end
  end

  defp verify_token(conn, token) do
    case AccessToken.verify_and_validate(token) do
      {:ok, claims} ->
        assign(conn, :request_context, %{auth: claims})

      error ->
        Logger.warn(fn -> "Token is invalid. Error: #{inspect(error)}" end)
        send_401(conn, "invalid_token")
    end
  end

  defp send_401(conn, message) do
    conn
    |> send_resp(401, message)
    |> halt()
  end
end
