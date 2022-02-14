defmodule GreenBankApi.Internal.ReportTest do
  use ExUnit.Case, async: true

  alias GreenBankApi.Repo
  alias GreenBankApi.Internal.{Transaction, Report}
  alias GreenBankApi.Internal.Account, as: AccountInternal

  @account_params %{
    "document" => 12_151_194_884,
    "account_holder" => "jose@hotmail.com",
    "password" => "12151194884"
  }

  @deposit_params %{
    "transaction_type" => "deposit",
    "amount" => 500,
    "payer" => "12151194884"
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    raw_date = Date.utc_today()

    year = Integer.to_string(raw_date.year)
    month = String.pad_leading(Integer.to_string(raw_date.month), 2, "0")
    day = String.pad_leading(Integer.to_string(raw_date.day), 2, "0")

    AccountInternal.register(@account_params)

    {:ok, %{year: year, month: month, day: day}}
  end

  describe "generate/2" do
    test "returns the amount transactioned based on a day (with transaction)", %{
      year: year,
      month: month,
      day: day
    } do
      Transaction.create(@deposit_params)

      {low_date, high_date} = Report.calculate_low_high_date(year, month, day)

      assert Decimal.eq?(Report.generate(low_date, high_date), @deposit_params["amount"])
    end

    test "returns the amount transactioned based on a day (no transaction)", %{
      year: year,
      month: month,
      day: day
    } do
      {low_date, high_date} = Report.calculate_low_high_date(year, month, day)

      refute Decimal.eq?(Report.generate(low_date, high_date), @deposit_params["amount"])
      assert Decimal.eq?(Report.generate(low_date, high_date), 0)
    end

    test "returns the amount transactioned based on a month (with transaction)", %{
      year: year,
      month: month
    } do
      Transaction.create(@deposit_params)

      {low_date, high_date} = Report.calculate_low_high_date(year, month, nil)

      assert Decimal.eq?(Report.generate(low_date, high_date), @deposit_params["amount"])
    end

    test "returns the amount transactioned based on a month (no transaction)", %{
      year: year,
      month: month
    } do
      {low_date, high_date} = Report.calculate_low_high_date(year, month, nil)

      refute Decimal.eq?(Report.generate(low_date, high_date), @deposit_params["amount"])
      assert Decimal.eq?(Report.generate(low_date, high_date), 0)
    end

    test "returns the amount transactioned based on a year (with transaction)", %{year: year} do
      Transaction.create(@deposit_params)

      {low_date, high_date} = Report.calculate_low_high_date(year, nil, nil)

      assert Decimal.eq?(Report.generate(low_date, high_date), @deposit_params["amount"])
    end

    test "returns the amount transactioned based on a year (with no transaction)", %{year: year} do
      {low_date, high_date} = Report.calculate_low_high_date(year, nil, nil)

      refute Decimal.eq?(Report.generate(low_date, high_date), @deposit_params["amount"])
      assert Decimal.eq?(Report.generate(low_date, high_date), 0)
    end
  end

  describe "generate/0" do
    test "returns the total amount transactioned (with transaction)" do
      Transaction.create(@deposit_params)

      assert Decimal.eq?(Report.generate(), @deposit_params["amount"])
    end

    test "returns the total amount transactioned (with no transaction)" do
      refute Decimal.eq?(Report.generate(), @deposit_params["amount"])
      assert Decimal.eq?(Report.generate(), 0)
    end
  end
end
