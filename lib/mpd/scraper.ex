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
    Mpd.Scraper.Scrape.go()
    Process.send_after(self(), :scrape, 30_000)
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  # def format_status(reason, pdict_and_state) do
  #   "whatever"
  # end

  # def terminate(reason, state) do
  #   "whatever"
  # end

  # def code_change(old_vsn, state, extra) do
  #   {:ok, state}
  #   # {:error, "reason"}
  # end

end
