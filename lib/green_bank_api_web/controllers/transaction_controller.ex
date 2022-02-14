defmodule GreenBankApiWeb.TransactionController do
  @moduledoc """
    Controller responsável por lidar com as requisições relacionadas a transações.
  """

  use GreenBankApiWeb, :controller

  alias GreenBankApi.Internal.Transaction, as: TransactionInternal

  plug GreenBankApiWeb.Plug.Session

  @doc """
    Cria uma transação. 

    Exemplo de parametros:
    {
    "payer": "43082810837",
    "transaction_type": "deposit",
    "amount": "1500"
    }

    Para transferência, é necessário incluir o payee (conta destino).
  """
  def create(conn, params) do
    make_transaction(conn, params)
  end

  defp make_transaction(conn, params) do
    transaction_params = %{
      "transaction_type" => params["transaction_type"],
      "payer" => params["payer"],
      "payee" => params["payee"],
      "amount" => params["amount"]
    }

    case TransactionInternal.create(transaction_params) do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, "The transaction was completed.")

      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(412, "wrong input check the documentation")
    end
  end
end
