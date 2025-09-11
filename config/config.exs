import Config

config :news_app, :feed_repo, StaticFeedRepository

config :news_app,
       :req_opts,
       http_errors: :raise,
       retry: :safe_transient,
       max_retries: 2

config :news_app, ecto_repos: [Repo]

config :news_app, Oban,
  repo: Repo,
  queues: [feeds: 10, feed_items: 10],
  plugins: [
    # prune old jobs periodically
    Oban.Plugins.Pruner,
    {
      Oban.Plugins.Cron,
      crontab: [
        {"*/15 * * * *", CronJob}
      ],
      timezone: "Europe/Helsinki"
    }
  ]

import_config "#{config_env()}.exs"
