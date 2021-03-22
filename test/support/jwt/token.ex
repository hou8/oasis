defmodule Oasis.Test.Support.AccessTokenSimple do
  @moduledoc false

  use Oasis.Jwt.AccessToken,
    iss: "oasis_test",
    default_exp: 1
end

defmodule Oasis.Test.Support.AccessTokenCustomClaimAlwaysFalse do
  @moduledoc false

  use Oasis.Jwt.AccessToken,
    iss: "oasis_test",
    default_exp: 1

  def add_custom_claims(config) do
    config
    |> add_claim("always_fail", fn -> "always_fail_value" end, fn _ -> false end)
  end
end

defmodule Oasis.Test.Support.AccessTokenCustomClaimAlwaysTrue do
  @moduledoc false

  use Oasis.Jwt.AccessToken,
    iss: "oasis_test",
    default_exp: 1

  def add_custom_claims(config) do
    config
    |> add_claim("always_success", fn -> "always_success_value" end, fn _ -> true end)
  end
end
