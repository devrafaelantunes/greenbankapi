defmodule GreenBankApi.Model.Session do
  @moduledoc """
    Model responsável por armazenar a sessão do usuário dentro do banco.
  """

  use Ecto.Schema

  alias GreenBankApi.Model.Account

  import Ecto.Changeset

  @primary_key {:session_id, :id, autogenerate: true}
  schema "session" do
    # Tipo da transação.
    field :token, :string

    belongs_to(:account, Account,
      foreign_key: :account_id,
      references: :account_id,
      on_replace: :delete
    )
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:token, :account_id])
    |> validate_required([:token, :account_id])
  end
end
