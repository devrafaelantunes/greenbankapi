defmodule GreenBankApiWeb.TransactionControllerTest do
  use GreenBankApiWeb.ConnCase
  use ExUnit.Case, async: true

  alias GreenBankApi.Internal.Account, as: AccountInternal

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

  setup do
    # Registra um usuário
    assert {:ok, _account} = AccountInternal.register(@account_params)

    {:ok, %{}}
  end

  describe "transaction endpoint/2" do
    test "create and complete a transaction with success", %{conn: conn} do
      # Pega o token gerado pelo login
      %{assigns: %{token: token}} = post(conn, Routes.session_path(conn, :login), @login_params)

      # Insere o token dentro do header de requisição
      conn =
        conn
        |> put_req_header("token", token)
        |> post(Routes.transaction_path(conn, :create), @transaction_params)

      # Verifica a resposta recebida pela API
      assert conn.resp_body =~ "The transaction was completed."
    end

    test "create and complete a transaction without success", %{conn: conn} do
      # Pega o token gerado pelo login
      %{assigns: %{token: token}} = post(conn, Routes.session_path(conn, :login), @login_params)

      # Insere o token dentro do header de requisição
      conn =
        conn
        |> put_req_header("token", token)
        # Modifica o valor da transação, forçando um erro.
        |> post(
          Routes.transaction_path(conn, :create),
          Map.put(@transaction_params, "amount", 2000)
        )

      # Verifica a resposta recebida pela API
      assert conn.resp_body =~ "wrong input"
    end

    test "creating a transaction without the token/logged in", %{conn: conn} do
      # Insere o token dentro do header de requisição
      conn =
        conn
        |> post(Routes.transaction_path(conn, :create), @transaction_params)

      # Verifica a resposta recebida pela API
      assert conn.resp_body =~ "the token is missing"
    end
  end
end
