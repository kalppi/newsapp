defmodule DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Repo
      import Ecto.Query
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    # If the test isn’t async, allow the test process (and spawned processes)
    # to share the same DB connection.
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end
