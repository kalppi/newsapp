defmodule FeedProcessor do
  defmodule FeedItem do
    use Ecto.Schema

    schema "feed_items" do
      field(:title, :string)
      field(:link, :string)
      field(:description, :string)
      field(:categories, {:array, :string})
      field(:published, :utc_datetime)
      timestamps()
    end
  end

  @behaviour FeedProcessorBehaviour
  require Logger

  @repo Application.compile_env(:news_app, :feed_repo, StaticFeedRepository)

  @spec process_feeds(module()) :: :ok
  def process_feeds(repo \\ @repo) do
    repo.list_feeds()
    |> Enum.map(&FeedJob.new(%{"url" => &1}))
    |> Oban.insert_all()

    :ok
  end

  @spec process_one(any()) ::
          {:error,
           binary() | %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()}}
          | {:ok, list()}
  def process_one(feed_url) do
    with {:ok, response} <- fetch_feed(feed_url),
         {:ok, feed} <- parse_feed(response.body),
         {:ok, items} <- handle_feed(feed) do
      Logger.info("Successfully processed feed: #{feed_url}")

      items
      |> Enum.map(&FeedItemJob.new(%{"url" => &1.link}))
      |> Oban.insert_all()

      insert_feed_items(items)

      {:ok, items}
    else
      {:error, reason} ->
        Logger.error("Error processing feed #{feed_url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp insert_feed_items(items) do
    Enum.each(items, fn item ->
      Repo.insert(item, on_conflict: :nothing, conflict_target: :link)
    end)
  end

  defp fetch_feed(feed_url) do
    opts = Application.get_env(:news_app, :req_opts, [])

    try do
      {:ok, Req.get!(feed_url, opts)}
    rescue
      e ->
        {:error, e}
    end
  end

  defp parse_feed(body) do
    try do
      FastRSS.parse_rss(body)
    rescue
      e -> {:error, e}
    end
  end

  defp handle_feed(feed) do
    items =
      for item <- Map.get(feed, "items", []) do
        published =
          case item["pub_date"] do
            nil -> nil
            date_str -> Timex.parse!(date_str, "{RFC1123}")
          end

        %FeedItem{
          title: item["title"],
          link: item["link"],
          description: item["description"],
          categories: Enum.map(item["categories"] || [], fn cat -> cat["name"] end),
          published: published
        }
      end

    {:ok, items}
  end
end
