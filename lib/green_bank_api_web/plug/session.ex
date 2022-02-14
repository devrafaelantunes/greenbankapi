defmodule GreenBankApiWeb.Plug.Session do
  @moduledoc """
    Esse plug é responsável por checar se o usuário está autenticado através de uma verificação
    de token.

    O token deverá ser passado através do header da requisição para que seja analisado.
  """
  import Plug.Conn

  alias GreenBankApi.Internal.Session, as: SessionInternal

  def init(opts), do: opts

  # Pattern match para a verificação vinda do controller GreenBankApiWeb.ReportController
  def call(
        %{params: %{"document" => document, "year" => _year, "month" => _month, "day" => _day}} =
          conn,
        _params
      ) do
    plug_authenticate(conn, document)
  end

  # Pattern match para a verificação vinda do controller GreenBankApiWeb.TransactionController
  def call(conn, _params) do
    plug_authenticate(conn, conn.params["payer"])
  end

  defp plug_authenticate(conn, document) do
    # Verifica se o token está nos headers
    if get_req_header(conn, "token") == [] do
      conn
      |> send_resp(401, "the token is missing")
      |> halt()
    else
      [token] = get_req_header(conn, "token")

      case SessionInternal.check_token(document, token) do
        {:error, reason} ->
          conn
          |> send_resp(401, "#{reason}")
          |> halt()

        _ ->
          conn
      end
    end
  end
end
