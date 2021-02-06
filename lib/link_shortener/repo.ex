defmodule LinkShortener.Repo do
  use Ecto.Repo,
    otp_app: :link_shortener,
    adapter: Ecto.Adapters.Postgres
end
