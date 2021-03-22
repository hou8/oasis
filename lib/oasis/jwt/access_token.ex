defmodule Oasis.Jwt.AccessToken do
  require Logger

  defmacro __using__(opts) do
    quote bind_quoted: [
            opts: opts
          ] do
      @iss Keyword.get(opts, :iss, "oasis")
      @aud Keyword.get(opts, :aud, "oasis")
      # default 30 min
      @default_exp Keyword.get(opts, :default_exp, 30 * 60)

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

  @callback add_custom_claims(Joken.token_config()) :: Joken.token_config()

  @callback add_custom_hooks(Joken.token_config()) :: Joken.token_config()
end
