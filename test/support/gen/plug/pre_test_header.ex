defmodule Oasis.Gen.Plug.PreTestHeader do
  use Oasis.Controller
  use Plug.ErrorHandler

  # Notice:
  # all header name are downcased when generate `pre-*` handler module

  plug(
    Oasis.Plug.RequestValidator,
    header_schema: %{
      "items" => %{
        "required" => true,
        "schema" => %ExJsonSchema.Schema.Root{
          schema: %{"items" => %{"type" => "integer"}, "type" => "array"}
        }
      }
    }
  )

  def call(conn, opts) do
    conn |> super(opts) |> Oasis.Gen.Plug.TestHeader.call(opts) |> halt()
  end

  defdelegate handle_errors(conn, error), to: Oasis.Gen.Plug.TestHeader

end
