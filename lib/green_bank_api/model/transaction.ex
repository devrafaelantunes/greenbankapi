defmodule GreenBankApi.Model.Transaction do
  @moduledoc """
    Model criada para armazenar todas as transações realizadas no banco.
  """
  use Ecto.Schema

  alias GreenBankApi.Model.Account

  import Ecto.Changeset

  @primary_key {:transaction_id, :id, autogenerate: true}
  schema "transaction" do
    # Tipo da transação.
    field :transaction_type, Ecto.Enum, values: [:wire_transfer, :deposit, :withdraw]
    field :transaction_datetime, :utc_datetime
    field :amount, :decimal

    # Cria um relacionamento com a tabela Account.
    # Toda transação precisa pertencer a um usuário do banco, nesse caso o payer.
    belongs_to(:payer_account, Account,
      foreign_key: :payer,
      references: :document,
      on_replace: :delete
    )

    # Se a transação for uma transferência, ela também precisa ter um destinatário (payee).
    belongs_to(:payee_account, Account,
      foreign_key: :payee,
      references: :document,
      on_replace: :delete
    )
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:transaction_type, :amount, :payer, :payee])
    |> validate_required([:transaction_type, :amount, :payer])
  end
end
