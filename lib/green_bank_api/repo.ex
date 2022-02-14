defmodule GreenBankApi.Repo do
  use Ecto.Repo,
    otp_app: :green_bank_api,
    adapter: Ecto.Adapters.Postgres

  # Não é bom realizar serializable transactions no ambiente de testes
  @serializable if Mix.env() == :test,
                  do: "",
                  else: "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE"

  @doc """
    As "serializable transactions" garantem um total isolamento da transação prevenindo qualquer anomalia.
    Sendo assim, elas são de extrema importância para o escopo do projeto.
  """
  def serializable_transaction(transaction) do
    __MODULE__.transaction(fn ->
      Ecto.Adapters.SQL.query(__MODULE__, @serializable)

      case __MODULE__.transaction(transaction) do
        {:ok, _} -> :completed
        {:error, _, reason, _} -> __MODULE__.rollback(reason)
      end
    end)
  end
end
