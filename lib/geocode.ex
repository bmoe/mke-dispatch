defmodule Geocode do

  import Ecto.Query

  def lookup(address) do
    IO.puts "Querying google for #{address}"
    %{ "lat" => lat, "lng" => lng} = HTTPoison.get!(url(address))
    |> Map.get(:body)
    |> Poison.decode!()
    |> Dict.get("results")
    |> case do
      [] -> [%{"geometry" => %{"location" => %{"lat" => nil, "lng" => nil}}}]
      res -> res
    end
    |> Enum.at(0)
    |> Dict.get("geometry")
    |> Dict.get("location")
    {:ok, {lat, lng}}
  end

  defp url(address) do
    "https://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&key=#{Application.get_env(:mpd, Geocode)[:google_api_key]}"
  end

end
