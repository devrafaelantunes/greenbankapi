defmodule GreenBankApi.Repo.Migrations.TransactionTable do
  use Ecto.Migration

  def change do
    create table("transaction") do
      add :transaction_id, :serial, primary_key: true
      add :transaction_type, :string
      add :transaction_datetime, :utc_datetime

      add :amount, :numeric

      add :payer, references(:account, column: :document, type: :bigint, on_delete: :delete_all)
      add :payee, references(:account, column: :document, type: :bigint, on_delete: :delete_all)
    end

    create index(:transaction, :transaction_datetime)
  end
end
