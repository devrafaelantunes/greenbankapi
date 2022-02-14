defmodule GreenBankApi.Internal.AccountTest do
  use ExUnit.Case, async: true

  alias GreenBankApi.Repo
  alias GreenBankApi.Internal.Account

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  @account_params %{
    "document" => 12_151_194_884,
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  describe "register/1" do
    test "with expected params" do
      assert {:ok, _account} = Account.register(@account_params)

      refute Account.fetch_by_document(Map.get(@account_params, "document")) == nil
    end

    test "with an invalid document" do
      updated_params = Map.put(@account_params, "document", "123")

      assert {:error, reason} = Account.register(updated_params)
      assert Account.fetch_by_document(Map.get(updated_params, "document")) == nil
      assert reason =~ "document field: is not valid"
    end

    test "with a valid document that has already been used" do
      assert {:ok, _account} = Account.register(@account_params)

      refute Account.fetch_by_document(Map.get(@account_params, "document")) == nil

      assert {:error, reason} = Account.register(@account_params)
      assert reason =~ "document field: has already been taken"
    end

    test "with an invalid password" do
      updated_params = Map.put(@account_params, "password", "123")

      assert {:error, reason} = Account.register(updated_params)
      assert Account.fetch_by_document(Map.get(updated_params, "document")) == nil
      assert reason =~ "password field: should be at least 7 character(s)"
    end

    test "with missing params" do
      updated_params = Map.drop(@account_params, ["password"])

      assert {:error, reason} = Account.register(updated_params)
      assert Account.fetch_by_document(Map.get(updated_params, "document")) == nil
      assert reason =~ "password field: can't be blank"
    end
  end
end
