defmodule MyApp.Router do
  use Plug.Router

  # MySQL connection settings
  @db_host "localhost"
  @db_user "username"
  @db_password "password"
  @db_name "dbname"

  plug :match
  plug :dispatch

  get "/users" do
    users = fetch_users()
    json(conn, users)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp fetch_users do
    {:ok, conn} = MyXQL.start_link(username: @db_user, password: @db_password, hostname: @db_host, database: @db_name)
    {:ok, result} = MyXQL.query!(conn, "SELECT * FROM users")
    MyXQL.stop(conn)

    result.rows
  end

  def json(conn, data) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Jason.encode!(data))
  end
end

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: MyApp.Router, options: [port: 8080])
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
