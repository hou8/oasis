defmodule Oasis.JwtTest do
  use ExUnit.Case, async: false

  alias Oasis.Test.Support.{TokenSimple}

  test "verify success" do
    {:ok, token, claims} = TokenSimple.generate_and_sign()
    {:ok, claims_verify} = TokenSimple.verify_and_validate(token)
    assert claims == claims_verify
  end

  test "verify exp timeout" do
    {:ok, token, claims} = TokenSimple.generate_and_sign()
    Process.sleep(1_100)
    {:error, messages} = TokenSimple.verify_and_validate(token)
    assert Keyword.fetch!(messages, :claim) == "exp"
  end

end
