import Config

config :news_app,
       :req_opts,
       retry: false,
       max_retries: 0,
       retry_log_level: false

config :news_app, Repo,
  database: "news_app_dev",
  username: "news_user",
  password: "news_user_password",
  hostname: "localhost",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :news_app, Oban, testing: :manual
