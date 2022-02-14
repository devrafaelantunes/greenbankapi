defmodule GreenBankApi.Model.TransactionTest do
  use ExUnit.Case, async: true

  alias GreenBankApi.Repo
  alias GreenBankApi.Model.Transaction

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  @sample_transaction_params %{
    "transaction_type" => "withdraw",
    "amount" => 500.00,
    "payer" => 12_151_194_884
  }

  describe "create_changeset/1" do
    test "with expected params" do
      transaction_changeset = Transaction.create_changeset(@sample_transaction_params)

      assert transaction_changeset.valid?
      assert transaction_changeset.errors == []
    end

    test "with missing params" do
      transaction_changeset =
        Map.drop(@sample_transaction_params, ["transaction_type"])
        |> Transaction.create_changeset()

      refute transaction_changeset.valid?

      assert transaction_changeset.errors == [
               {:transaction_type, {"can't be blank", [validation: :required]}}
             ]
    end
  end
end
