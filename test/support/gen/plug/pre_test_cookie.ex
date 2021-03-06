defmodule Oasis.Gen.Plug.PreTestCookie do
  use Oasis.Controller
  use Plug.ErrorHandler

  plug(
    Oasis.Plug.RequestValidator,
    cookie_schema: %{
      "items" => %{
        "required" => true,
        "schema" => %ExJsonSchema.Schema.Root{
          schema: %{"items" => %{"type" => "number"}, "type" => "array"}
        }
      }
    }
  )

  def call(conn, opts) do
    conn |> super(opts) |> Oasis.Gen.Plug.TestCookie.call(opts) |> halt()
  end

  defdelegate handle_errors(conn, error), to: Oasis.Gen.Plug.TestCookie

end
