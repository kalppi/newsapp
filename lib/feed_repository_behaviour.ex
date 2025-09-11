defmodule FeedRepositoryBehaviour do
  @callback list_feeds() :: [String.t()]
end
