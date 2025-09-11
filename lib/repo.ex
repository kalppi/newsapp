defmodule Repo do
  use Ecto.Repo,
    otp_app: :news_app,
    adapter: Ecto.Adapters.Postgres
end
