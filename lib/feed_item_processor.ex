defmodule FeedItemProcessor do
  @behaviour FeedItemProcessorBehaviour
  require Logger

  def process_one(item_url) do
    with {:ok, response} <- fetch_item(item_url),
         {:ok, content} <- handle_item(response) do
      {:ok, content}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_item(feed_url) do
    opts = Application.get_env(:news_app, :req_opts, [])

    try do
      {:ok, Req.get!(feed_url, opts)}
    rescue
      e ->
        {:error, e}
    end
  end

  defp handle_item(response) do
    {:ok, response.body}
  end
end
