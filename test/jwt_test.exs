defmodule Oasis.JwtTest do
  use ExUnit.Case, async: false

  alias Oasis.Jwt.{AccessToken, RefreshToken}

  test "verify success" do
    {:ok, token, _claims} = AccessToken.generate_and_sign(%{test_extra: 1})
    {:ok, claims_verify} = AccessToken.verify_and_validate(token)
    assert Map.fetch!(claims_verify, "test_extra") == 1
  end

  test "verify exp timeout" do
    {:ok, access_token, _claims} = AccessToken.generate_and_sign()
    {:ok, refresh_token, _claims} = RefreshToken.generate_and_sign()
    Process.sleep(1_100)
    {:error, messages} = AccessToken.verify_and_validate(access_token)
    assert Keyword.fetch!(messages, :claim) == "exp"
    {:ok, claims_verify} = RefreshToken.verify_and_validate(refresh_token)
  end
end
