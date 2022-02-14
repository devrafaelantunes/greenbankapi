defmodule GreenBankApi.Repo.Migrations.AccountsTable do
  use Ecto.Migration

  def change do
    create table("account") do
      add :account_id, :serial, primary_key: true

      add :document, :bigint
      add :account_holder, :string

      add :branch_number, :integer
      add :account_number, :integer

      add :balance, :numeric

      add :password_hash, :string

      timestamps()
    end

    create unique_index(:account, [:account_id])
    create unique_index(:account, [:document])
  end
end
