defmodule ObanCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Oban.Testing, repo: Repo
    end
  end
end
