defmodule GreenBankApi.Internal.TransactionTest do
  use ExUnit.Case, async: true

  alias GreenBankApi.Repo
  alias GreenBankApi.Internal.Transaction
  alias GreenBankApi.Model.Account, as: AccountModel
  alias GreenBankApi.Internal.Account, as: AccountInternal

  @payer_params %{
    "document" => 12_151_194_884,
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  @payee_params %{
    "document" => 43_082_810_837,
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, payer} = AccountInternal.register(@payer_params)
    {:ok, payee} = AccountInternal.register(@payee_params)

    {:ok, %{payer: payer, payee: payee}}
  end

  describe "Transaction.create/1 (withdraw)" do
    test "withdraw with enough funds", %{payer: payer} do
      # Initial balance
      assert Decimal.eq?(payer.balance, 1000)

      withdraw_params = %{
        "transaction_type" => "withdraw",
        "amount" => 500,
        "payer" => payer.document
      }

      assert {:ok, :completed} = Transaction.create(withdraw_params)

      updated_payer_account = Repo.get_by(AccountModel, document: payer.document)

      assert Decimal.eq?(updated_payer_account.balance, 500)
    end

    test "withdraw with no enough funds", %{payer: payer} do
      # Initial balance
      assert Decimal.eq?(payer.balance, 1000)

      withdraw_params = %{
        "transaction_type" => "withdraw",
        "amount" => 1500,
        "payer" => payer.document
      }

      assert {:error, :not_enough_funds} = Transaction.create(withdraw_params)

      updated_payer_account = Repo.get_by(AccountModel, document: payer.document)

      assert Decimal.eq?(updated_payer_account.balance, payer.balance)
    end

    test "withdraw with an inexsting account" do
      withdraw_params = %{
        "transaction_type" => "withdraw",
        "amount" => 500,
        "payer" => "123"
      }

      assert {:error, :account_not_found} = Transaction.create(withdraw_params)
    end
  end

  describe "Transaction.create/1 (deposit)" do
    test "deposit", %{payer: payer} do
      # Initial balance
      assert Decimal.eq?(payer.balance, 1000)

      deposit_params = %{
        "transaction_type" => "deposit",
        "amount" => 500,
        "payer" => payer.document
      }

      assert {:ok, :completed} = Transaction.create(deposit_params)

      updated_payer_account = Repo.get_by(AccountModel, document: payer.document)

      assert Decimal.eq?(updated_payer_account.balance, 1500)
    end

    test "deposit in an inexsting account" do
      deposit_params = %{
        "transaction_type" => "withdraw",
        "amount" => 500,
        "payer" => 123
      }

      assert {:error, :account_not_found} = Transaction.create(deposit_params)
    end
  end

  describe "Transaction.create/1 (wire_transfer)" do
    test "transfer with enough funds", %{payer: payer, payee: payee} do
      # Initial balance
      assert Decimal.eq?(payer.balance, 1000)

      transfer_params = %{
        "transaction_type" => "wire_transfer",
        "amount" => 500,
        "payer" => payer.document,
        "payee" => payee.document
      }

      assert {:ok, :completed} = Transaction.create(transfer_params)

      updated_payer_account = Repo.get_by(AccountModel, document: payer.document)
      updated_payee_account = Repo.get_by(AccountModel, document: payee.document)

      assert Decimal.eq?(updated_payer_account.balance, 500)
      assert Decimal.eq?(updated_payee_account.balance, 1500)
    end

    test "transfer with not enough funds", %{payer: payer, payee: payee} do
      # Initial balance
      assert Decimal.eq?(payer.balance, 1000)

      transfer_params = %{
        "transaction_type" => "wire_transfer",
        "amount" => 1500,
        "payer" => payer.document,
        "payee" => payee.document
      }

      assert {:error, :not_enough_funds} = Transaction.create(transfer_params)

      updated_payer_account = Repo.get_by(AccountModel, document: payer.document)
      updated_payee_account = Repo.get_by(AccountModel, document: payee.document)

      assert Decimal.eq?(updated_payer_account.balance, payer.balance)
      assert Decimal.eq?(updated_payee_account.balance, payee.balance)
    end

    test "transfer to an inexsting account", %{payer: _payer, payee: payee} do
      transfer_params = %{
        "transaction_type" => "wire_transfer",
        "amount" => 1500,
        "payer" => 123,
        "payee" => payee.document
      }

      assert {:error, :account_not_found} = Transaction.create(transfer_params)
    end
  end
end
