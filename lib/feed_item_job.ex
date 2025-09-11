defmodule FeedItemJob do
  use Oban.Worker,
    queue: :feed_items,
    max_attempts: 5,
    # prevent dupes for an hour
    unique: [fields: [:worker, :args], period: 60 * 60]

  @impl true
  def perform(%Oban.Job{args: %{"url" => url}}) do
    try do
      FeedItemProcessor.process_one(url)
    rescue
      e ->
        {:error, e}
    end
  end
end
