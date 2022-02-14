defmodule GreenBankApi.Repo.Migrations.SessionTable do
  use Ecto.Migration

  def change do
    create table("session") do
      add :session_id, :serial, primary_key: true
      add :token, :string

      add :account_id, references(:account, column: :account_id, on_delete: :delete_all)
    end
  end
end
