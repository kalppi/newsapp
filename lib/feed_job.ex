defmodule FeedJob do
  use Oban.Worker,
    queue: :feeds,
    max_attempts: 5,
    # prevent dupes for an hour
    unique: [fields: [:worker, :args], period: 60 * 60]

  @impl true
  def perform(%Oban.Job{args: %{"url" => url}}) do
    try do
      FeedProcessor.process_one(url)
    rescue
      e ->
        {:error, e}
    end
  end
end
