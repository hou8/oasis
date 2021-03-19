defmodule Oasis.Test.Support.TokenSimple do
  @moduledoc false

  @signer Joken.Signer.create("HS256", "s3cret")

  use Oasis.Jwt,
      iss: "oasis_test",
      default_exp: 1
end
