defmodule Mpd.Scraper.Db do
  alias Mpd.Repo
  alias Mpd.Calls.Call

  require Logger

  import Ecto.Query

  def insert(call) do
    # Cast :time to native time
    {_, call} = Map.get_and_update!(
      call, :time, fn(current_time) ->
        {current_time, Timex.parse!(current_time, "{0M}/{0D}/{YYYY} {h12}:{m}:{s} {AM}")}
      end
    )
    call_id = call.call_id
    with query <- from(c in Call, where: c.call_id == ^call_id, order_by: [desc: c.inserted_at], limit: 10),
         related_calls <- Repo.all(query),
           true <- is_unique(call, related_calls),
           geocoded_call <- geocode(call, related_calls) do
      Repo.insert!(Call.changeset(%Call{}, Map.from_struct(geocoded_call)))
      call
    else
      _ -> nil
    end
  end

  defp is_unique(call, calls) do
    matching_calls = Enum.filter(calls, &(call.status == &1.status && call.nature == &1.nature))
    matching_calls == []
  end

  defp geocode(call, related_calls) do
    geocoded_calls = Enum.filter(related_calls, &(&1.point != nil))
    point = case geocoded_calls do
              [c | _] ->
                Logger.info("using related: #{inspect c}")
                c.point
              [] ->
                {:ok, latlong} = Geocode.lookup(call.location)
                case latlong do
                  {nil, nil} -> nil
                  {_lat, _long} -> %Geo.Point{coordinates: latlong, srid: 4326}
                  _ -> nil
                end
            end
    Map.put(call, :point, point)
  end

end
