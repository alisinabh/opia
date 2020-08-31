defmodule Opia.Router do
  @moduledoc """
  Router for handling requests to opia.
  """

  use Plug.Router
  use Plug.ErrorHandler

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  require Logger

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(:match)

  plug(:dispatch)

  get "/healthz" do
    send_resp(conn, 200, "OK")
  end

  match "/i/:size/*resource_path" do
    Logger.debug(inspect(conn, pretty: true))

    [scheme, domain | rest] = conn.params["resource_path"]

    scheme =
      case scheme do
        "http" -> "http:"
        "https" -> "https:"
        "http:" -> "http:"
        "https:" -> "https:"
      end

    url = Path.join(["#{scheme}//#{domain}" | rest]) <> "?#{conn.query_string}"
    Logger.debug(url)
    {:ok, resp} = HTTPoison.get(url)
    :ok = File.write("test.jpg", resp.body)
    import Mogrify

    r =
      "test.jpg"
      |> open()
      |> resize_to_limit(conn.params["size"])
      |> save()

    conn
    |> send_resp(resp.status_code, File.read!(r.path))
  end

  match _ do
    [scheme, domain | rest] = conn.path_info

    scheme =
      case scheme do
        "http" -> "http:"
        "https" -> "https:"
        "http:" -> "http:"
        "https:" -> "https:"
      end

    url = Path.join(["#{scheme}//#{domain}" | rest]) <> "?#{conn.query_string}"
    Logger.debug(url)
    {:ok, resp} = HTTPoison.get(url)

    conn
    |> send_resp(resp.status_code, resp.body)
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack} = error) do
    Logger.error("Unhandled error: #{inspect(error)}")
    send_resp(conn, conn.status, "Something went wrong")
  end
end
