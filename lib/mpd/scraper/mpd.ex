defmodule Mpd.Scraper.Mpd do

  @enforce_keys [:call_id, :time, :location, :district, :nature, :status]
  defstruct [:call_id, :time, :location, :district, :nature, :status]

end
