defmodule Mpd.Scraper.Db do
  alias Mpd.Repo
  alias Mpd.Calls.Call

  import Ecto.Query

  def insert_scraped_call(call) do
    # Cast :time to native time
    {_, call} = Map.get_and_update!(
      call, :time, fn(current_time) ->
        {current_time, Timex.parse!(current_time, "{0M}/{0D}/{YYYY} {h12}:{m}:{s} {AM}")}
      end
    )

    # Look for most recent related call, which might be a duplicate.
    # XXX What if we have a dup is not the most recent?
    call_id = call.call_id
    rcall = from(c in Call, where: c.call_id == ^call_id, order_by: [desc: c.inserted_at], limit: 1) |> Repo.one

    case rcall do
      nil   ->
        call = case Geocode.lookup(call.location) do
                 {nil, nil} ->
                   call
                 {lat, lng} ->
                   Map.put(call, :point, %Geo.Point{coordinates: {lng, lat}, srid: 4326})
               end
        # MkePolice.Endpoint.broadcast("calls:all", "new", rcall)
        # MkePolice.Endpoint.broadcast("calls:#{rcall.district}", "new", rcall)
        Repo.insert!(Call.changeset(%Call{}, Map.from_struct(call)))
      rcall ->
        if(rcall.status != call.status || rcall.nature != call.nature) do
          # MkePolice.Endpoint.broadcast("calls:all", "new", rcall)
          # MkePolice.Endpoint.broadcast("calls:#{rcall.district}", "new", rcall)
          call = Map.put(call, :point, rcall.point)
          Repo.insert!(Call.changeset(%Call{}, Map.from_struct(call)))
        end
    end
  end

end
