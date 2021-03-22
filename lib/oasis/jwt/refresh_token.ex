defmodule Oasis.Jwt.RefreshToken do
  require Logger

  @callback add_custom_claims(Joken.token_config()) :: Joken.token_config()

  @callback add_custom_hooks(Joken.token_config()) :: Joken.token_config()

  defmacro __using__(opts) do
    quote bind_quoted: [
            opts: opts
          ] do
      @iss Keyword.get(opts, :iss, "oasis")
      @aud Keyword.get(opts, :aud, "oasis")
      # default 3 day
      @default_exp Keyword.get(opts, :default_exp, 3 * 24 * 60 * 60)

      use Joken.Config,
        default_signer: :access_token_secret_key

      @impl true
      def token_config do
        [iss: @iss, aud: @aud, default_exp: @default_exp]
        |> default_claims()
        |> add_custom_claims()
        |> add_custom_hooks()
      end

      def add_custom_claims(config), do: config

      def add_custom_hooks(config), do: config

      defoverridable add_custom_claims: 1,
                     add_custom_hooks: 1
    end
  end
end
