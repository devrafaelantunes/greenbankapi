defmodule GreenBankApiWeb.ReportControllerTest do
  use GreenBankApiWeb.ConnCase
  use ExUnit.Case, async: true

  alias GreenBankApi.Internal.Account, as: AccountInternal
  alias GreenBankApi.Internal.Transaction, as: TransactionInternal

  @account_params %{
    "document" => 12_151_194_884,
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  @login_params %{
    "document" => 12_151_194_884,
    "password" => "1234567"
  }

  @transaction_params %{
    "transaction_type" => "withdraw",
    "amount" => 500,
    "payer" => @account_params["document"]
  }

  @report_per_period_params %{
    "document" => @account_params["document"],
    "day" => "nil",
    "month" => "nil",
    "year" => "2022"
  }

  @total_report_params %{
    "document" => @account_params["document"],
    "day" => "nil",
    "month" => "nil",
    "year" => "nil"
  }

  setup do
    # Registra um usuário
    assert {:ok, _account} = AccountInternal.register(@account_params)

    # Cria uma transação
    TransactionInternal.create(@transaction_params)

    {:ok, %{}}
  end

  describe "report endpoint/2" do
    test "return the amount transactioned in a certain period", %{conn: conn} do
      # Pega o token gerado pelo login
      %{assigns: %{token: token}} = post(conn, Routes.session_path(conn, :login), @login_params)

      # Insere o token dentro do header de requisição
      conn =
        conn
        |> put_req_header("token", token)
        |> get(Routes.report_path(conn, :create), @report_per_period_params)

      # Verifica a resposta recebida pela API
      assert conn.resp_body =~
               "The total transactioned between 2022-01-01 00:00:00Z and 2022-12-31 23:59:59Z - R$#{@transaction_params["amount"]}"
    end

    test "return all the amount transactioned", %{conn: conn} do
      # Pega o token gerado pelo login
      %{assigns: %{token: token}} = post(conn, Routes.session_path(conn, :login), @login_params)

      # Insere o token dentro do header de requisição
      conn =
        conn
        |> put_req_header("token", token)
        |> get(Routes.report_path(conn, :create), @total_report_params)

      # Verifica a resposta recebida pela API
      assert conn.resp_body =~ "The total transactioned is R$#{@transaction_params["amount"]}"
    end

    test "trying to generate the report without the token/logged in", %{conn: conn} do
      # Faz a requisição
      conn =
        conn
        |> get(Routes.report_path(conn, :create), @total_report_params)

      # Verifica a resposta recebida pela API
      assert conn.resp_body =~ "the token is missing"
    end
  end
end
