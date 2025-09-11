defmodule StaticFeedRepository do
  @behaviour FeedRepositoryBehaviour

  @moduledoc """
  Repository for news RSS feed addresses.
  """

  @feeds [
    "https://www.iltalehti.fi/rss/uutiset.xml",
    "https://www.iltalehti.fi/rss/urheilu.xml"
  ]

  @doc """
  Returns a static list of RSS feed addresses.
  """
  @impl true
  def list_feeds do
    @feeds
  end
end
