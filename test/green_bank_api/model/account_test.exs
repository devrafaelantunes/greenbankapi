defmodule GreenBankApi.Model.AccountTest do
  use ExUnit.Case, async: true

  alias GreenBankApi.Repo
  alias GreenBankApi.Model.Account

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  @account_params %{
    "document" => "12151194884",
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  describe "create_changeset/1" do
    test "with expected params" do
      account_changeset = Account.create_changeset(@account_params)

      assert account_changeset.valid?
      assert account_changeset.errors == []
    end

    test "with missing params" do
      account_changeset =
        Map.drop(@account_params, ["document"])
        |> Account.create_changeset()

      refute account_changeset.valid?

      assert account_changeset.errors == [
               document: {"can't be blank", [{:validation, :required}]}
             ]
    end

    test "with an invalid document" do
      account_changeset =
        Map.put(@account_params, "document", "123")
        |> Account.create_changeset()

      refute account_changeset.valid?
      assert account_changeset.errors == [document: {"is not valid", []}]
    end

    test "with a short password" do
      account_changeset =
        Map.put(@account_params, "password", "123")
        |> Account.create_changeset()

      refute account_changeset.valid?
      # Reformular essa merda aqui
      assert account_changeset.errors == [
               password: {
                 "should be at least %{count} character(s)",
                 [
                   {:count, 7},
                   {:validation, :length},
                   {:kind, :min},
                   {:type, :string}
                 ]
               }
             ]
    end
  end
end
