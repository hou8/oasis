defmodule Oasis.Gen.Plug.PreTestBearerAuth do
  use Oasis.Controller
  use Plug.ErrorHandler

  plug(
    Oasis.Plug.RequestValidator,
    query_schema: %{
      "max_age" => %{
        "schema" => %ExJsonSchema.Schema.Root{
          schema: %{"type" => "integer"}
        },
        "required" => false
      }
    }
  )

  plug(
    Oasis.Plug.BearerAuth,
    security: Oasis.Gen.BearerAuth,
    key_to_assigns: :id
  )

  def call(conn, opts) do
    conn |> super(conn) |> Oasis.Gen.Plug.TestBearerAuth.call(opts) |> halt()
  end

  defdelegate handle_errors(conn, error), to: Oasis.Gen.Plug.TestBearerAuth

end
