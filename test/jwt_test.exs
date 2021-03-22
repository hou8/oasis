defmodule Oasis.JwtTest do
  use ExUnit.Case, async: false

  alias Oasis.Test.Support.{
    AccessTokenSimple,
    AccessTokenCustomClaimAlwaysFalse,
    AccessTokenCustomClaimAlwaysTrue
  }

  test "verify success" do
    {:ok, token, _claims} = AccessTokenSimple.generate_and_sign(%{test_extra: 1})
    {:ok, claims_verify} = AccessTokenSimple.verify_and_validate(token)
    assert Map.fetch!(claims_verify, "test_extra") == 1
  end

  test "verify exp timeout" do
    {:ok, token, _claims} = AccessTokenSimple.generate_and_sign()
    Process.sleep(1_100)
    {:error, messages} = AccessTokenSimple.verify_and_validate(token)
    assert Keyword.fetch!(messages, :claim) == "exp"
  end

  test "custom claim verify fail" do
    {:ok, token, _claims} = AccessTokenCustomClaimAlwaysFalse.generate_and_sign()
    {:error, error} = AccessTokenCustomClaimAlwaysFalse.verify_and_validate(token)
    assert error[:claim] == "always_fail"
  end

  test "custom claim verify success" do
    {:ok, token, _claims} = AccessTokenCustomClaimAlwaysTrue.generate_and_sign()
    {:ok, claims_verify} = AccessTokenCustomClaimAlwaysTrue.verify_and_validate(token)
    assert Map.fetch!(claims_verify, "always_success") == "always_success_value"
  end
end
