defmodule CronJob do
  use Oban.Worker, queue: :default, max_attempts: 5

  @impl true
  def perform(_job) do
    FeedProcessor.process_feeds()
    :ok
  end
end
