defmodule FeedItemProcessorTest do
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
    path = "/item"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.expect(bypass, "GET", path, fn conn ->
      Plug.Conn.resp(conn, 200, "Hello world")
    end)

    url
  end

  test "jobs are processed successfully" do
    url = create_bypass_feed()

    capture_log(fn ->
      {:ok, content} = perform_job(FeedItemJob, %{url: url})

      assert "Hello world" = content
    end)
  end
end
