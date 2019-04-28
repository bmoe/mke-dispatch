defmodule Mpd.Scraper.Scrape do
  alias Mpd.Repo
  alias Mpd.Calls.Call

  import Ecto.Query

  def do_a_scrape do
    calls()
    |> Enum.each(fn(call) ->
      call_id = call[:call_id]
      rcall = from(c in Call, where: c.call_id == ^call_id, order_by: [desc: c.inserted_at], limit: 1) |> Repo.one
      {_, call} = Map.get_and_update!(call, :time, fn(current_time) ->
        {current_time, Timex.parse!(current_time, "{0M}/{0D}/{YYYY} {h12}:{m}:{s} {AM}")}
      end)
      case rcall do
        nil   ->
          call = case Geocode.lookup(call.location) do
                   {nil, nil} ->
                     IO.puts("No location for #{call.location}")
                     call
                   {lat, lng} ->
                     IO.puts("Location for #{call.location} is #{lat}/#{lng}")
                     Map.put(call, :point, %Geo.Point{coordinates: {lng, lat}, srid: 4326})
                 end
          # MkePolice.Endpoint.broadcast("calls:all", "new", rcall)
          # MkePolice.Endpoint.broadcast("calls:#{rcall.district}", "new", rcall)
          rcall = Repo.insert!(Call.changeset(%Call{}, call))
        rcall ->
          if(rcall.status != call[:status] || rcall.nature != call[:nature]) do
            # MkePolice.Endpoint.broadcast("calls:all", "new", rcall)
            # MkePolice.Endpoint.broadcast("calls:#{rcall.district}", "new", rcall)
            call = Map.put(call, :point, rcall.point)
            rcall = Repo.insert!(Call.changeset(%Call{}, call))
          end
      end
    end)
  end

  def calls do
    Mpd.Scraper.Scraper.fetch
  end
end
