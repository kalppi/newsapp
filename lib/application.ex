defmodule NewsApplication do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Ecto Repo (DB connection pool)
      Repo,

      # Oban (reads config from config/config.exs)
      {Oban, Application.fetch_env!(:news_app, Oban)},

      # Optional: a Task.Supervisor for parallel work
      {Task.Supervisor, name: TaskSupervisor, max_restarts: 10, max_seconds: 60}
    ]

    # If one child dies, only that child restarts
    opts = [strategy: :one_for_one, name: Supervisor]
    Supervisor.start_link(children, opts)
  end
end
