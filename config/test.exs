use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mpd, MpdWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :mpd, MpdData,
  url: "http://localhost:9000/sample-page.html"

# Configure your database
config :mpd, Mpd.Repo,
  username: "postgres",
  password: "postgres",
  database: "mpd_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
