defmodule Mpd.Scraper do
  use GenServer

  def start_link args, opts \\ [] do
    GenServer.start_link(__MODULE__, [args], opts)
  end

  def init args do
    IO.puts("Starting the scraper")
    send(self(), :scrape)
    {:ok, args}
  end

  def handle_call(_message, _from, state) do
    {:reply, "", state}
  end

  def handle_cast(_message, state) do
    {:noreply, state}
  end

  def handle_info(:scrape, state) do
    IO.puts("scraping #{DateTime.utc_now()}")
    Mpd.Scraper.MpdData.fetch() |>
      Enum.each(&Mpd.Scraper.Db.insert_scraped_call(&1))
    IO.puts("done scraping #{DateTime.utc_now()}. next scrape in 20 minutes")
    Process.send_after(self(), :scrape, 1200_000)
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

end
