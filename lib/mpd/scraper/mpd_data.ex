defmodule Mpd.Scraper.MpdData do

  require Logger

  @enforce_keys [:call_id, :time, :location, :district, :nature, :status]
  defstruct [:call_id, :time, :location, :district, :nature, :status]

  @mpd_url Application.get_env(:mpd, MpdData)[:url]

  def fetch do
    fetch(@mpd_url)
  end

  def fetch(url) do
    # Status 429 too many requests.
    # But only if they did their site right. Which they did not.
    with result <- HTTPoison.get!(url),
         Logger.debug("Status: #{result.status_code}"),
         {:status_code, 200} <- {:status_code, result.status_code},
         {:rate_limited, false} <- {:rate_limited, rate_limited(result)} do
      result
      |> Map.get(:body)
      |> Floki.find(".content table > tbody > tr")
      |> Enum.map(&parse_row/1)
    else
      {:status_code, status_code} ->
        Logger.error("Bad status. HTTP status code: #{status_code}")
        []
      {:rate_limited, true} ->
        Logger.error("Rate Limited.")
        []
    end
  end

  defp rate_limited(result) do
    String.contains?(result.body, "You will be denied results until your number of calls is a reasonable number")
  end

  defp parse_row({_tr, _attrs, children}) do
    %Mpd.Scraper.MpdData{
      call_id: Enum.at(children, 0) |> parse_cell(),
      time: Enum.at(children, 1) |> parse_time_cell(),
      location: Enum.at(children, 2) |> parse_cell(),
      district: Enum.at(children, 3) |> parse_district_cell(),
      nature: Enum.at(children, 4) |> parse_cell(),
      status: Enum.at(children, 5) |> parse_cell()
    }
  end


  defp parse_cell(nil), do: ""
  defp parse_cell({_el, _, children}) do
    Enum.at(children, 0)
  end

  defp parse_cell(rest) do
    rest
  end


  defp parse_district_cell({_el, _, children}) do
    case Enum.at(children, 0) do
      nil -> nil
      {"input", _, _} -> nil
      cell -> parse_cell(cell)
    end
  end

  defp parse_time_cell({_el, _ , children}) do
    case Enum.at(children, 0) do
      nil -> nil
      {"input", _, _} -> nil
      cell -> parse_cell(cell)
    end
  end
end
