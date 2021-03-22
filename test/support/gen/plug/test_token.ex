defmodule Oasis.Gen.Plug.TestToken do
  # NOTICE: This module is generated from the corresponding mix task command to the OpenAPI Specification
  # in the first time running, and then it WON'T be modified in the ongoing generation command(s)
  # once this file exists, you may write your business code base on this module.
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(%{halted: true} = conn, _opts), do: conn

  def call(conn, _opts) do
    conn
    |> send_resp(200, Jason.encode!(%{"message" => "pass"}))
  end

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    message = Map.get(reason, :message, "Something went wrong")
    send_resp(conn, conn.status, message)
  end
end
