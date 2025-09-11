import Config

config :news_app, Repo,
  database: "news_app_dev",
  username: "news_user",
  password: "news_user_password",
  hostname: "localhost",
  port: 5433,
  pool_size: 10
