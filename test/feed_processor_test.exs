Mox.defmock(FeedRepoMock, for: FeedRepositoryBehaviour)

defmodule FeedProcessorTest do
  use ExUnit.Case, async: true
  use ObanCase, async: true
  use DataCase, async: true

  import Mox
  import ExUnit.CaptureLog

  setup :verify_on_exit!

  setup do
    Oban.Job |> Oban.delete_all_jobs()
    :ok
  end

  defp create_bypass_feed() do
    bypass = Bypass.open()
    path = "/feed.xml"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.expect(bypass, "GET", path, fn conn ->
      items = [
        %FeedProcessor.FeedItem{
          title: "Hello",
          link: "http://example.com/hello",
          published: "Mon, 01 Jan 2024 00:00:00 GMT",
          description: "desc",
          categories: ["stuff", "and more"]
        }
      ]

      Plug.Conn.resp(conn, 200, rss_xml(items))
    end)

    url
  end

  defp rss_xml(items) do
    items_xml =
      Enum.map(items, fn %FeedProcessor.FeedItem{
                           title: title,
                           link: link,
                           published: pubDate,
                           description: description,
                           categories: categories
                         } ->
        categories_xml =
          Enum.map(categories || [], fn category ->
            "<category>#{category}</category>"
          end)
          |> Enum.join("\n")

        """
        <item>
          <title>#{title}</title>
          <link>#{link}</link>
          <pubDate>#{pubDate}</pubDate>
          <description>#{description}</description>
          #{categories_xml}
        </item>
        """
      end)
      |> Enum.join("\n")

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>Test Feed</title>
        <link>http://example.com</link>
        <description>Test</description>
        #{items_xml}
      </channel>
    </rss>
    """
  end

  test "jobs are enqueued" do
    expect(FeedRepoMock, :list_feeds, fn -> ["url/feed1.xml", "url/feed2.xml"] end)

    assert :ok =
             FeedProcessor.process_feeds(FeedRepoMock)

    assert_enqueued(worker: FeedJob, args: %{"url" => "url/feed1.xml"}, queue: "feeds")
    assert_enqueued(worker: FeedJob, args: %{"url" => "url/feed2.xml"}, queue: "feeds")

    assert jobs = all_enqueued(worker: FeedJob)
    assert 2 == length(jobs)
  end

  test "jobs are enqueued with default repository" do
    Application.put_env(:news_app, :feed_repo, FeedRepoMock)

    expect(FeedRepoMock, :list_feeds, fn -> ["url/feed1.xml", "url/feed2.xml"] end)

    assert :ok =
             FeedProcessor.process_feeds(FeedRepoMock)

    assert_enqueued(worker: FeedJob, args: %{"url" => "url/feed1.xml"}, queue: "feeds")
    assert_enqueued(worker: FeedJob, args: %{"url" => "url/feed2.xml"}, queue: "feeds")

    assert jobs = all_enqueued(worker: FeedJob)
    assert 2 == length(jobs)
  end

  test "feed items are stored" do
    url = create_bypass_feed()

    capture_log(fn ->
      {:ok, _items} = perform_job(FeedJob, %{url: url})

      db_items = Repo.all(FeedProcessor.FeedItem)

      assert Enum.any?(db_items, fn item ->
               item.title == "Hello" && item.link == "http://example.com/hello"
             end)

      assert length(db_items) == 1
    end)
  end

  test "jobs are processed successfully" do
    url = create_bypass_feed()

    capture_log(fn ->
      {:ok, items} = perform_job(FeedJob, %{url: url})

      published_dt = Timex.parse!("Mon, 01 Jan 2024 00:00:00 GMT", "{RFC1123}")

      assert [
               %FeedProcessor.FeedItem{
                 title: "Hello",
                 link: "http://example.com/hello",
                 published: ^published_dt,
                 description: "desc",
                 categories: ["stuff", "and more"]
               }
             ] = items
    end)
  end

  test "processing jobs enqueues item jobs" do
    url = create_bypass_feed()

    capture_log(fn ->
      {:ok, _items} = perform_job(FeedJob, %{url: url})

      assert_enqueued(
        worker: FeedItemJob,
        args: %{"url" => "http://example.com/hello"},
        queue: "feed_items"
      )

      assert item_jobs = all_enqueued(worker: FeedItemJob)
      assert 1 == length(item_jobs)
    end)
  end

  test "jobs can error" do
    bypass = Bypass.open()
    path = "/feed.xml"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.expect(bypass, "GET", path, fn conn ->
      Plug.Conn.resp(conn, 500, "Internal Server Error")
    end)

    capture_log(fn ->
      {:error, %RuntimeError{message: message}} = perform_job(FeedJob, %{url: url})

      assert message =~ "Internal Server Error"
    end)
  end
end
