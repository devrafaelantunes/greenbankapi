defmodule GreenBankApiWeb.SessionControllerTest do
  use GreenBankApiWeb.ConnCase
  use ExUnit.Case, async: true

  alias GreenBankApi.Internal.Account, as: AccountInternal

  @login_params %{
    "document" => 12_151_194_884,
    "password" => "1234567"
  }

  @account_params %{
    "document" => 12_151_194_884,
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  describe "login endpoint/2" do
    test "login with correct parameters", %{conn: conn} do
      assert {:ok, _account} = AccountInternal.register(@account_params)

      conn = post(conn, Routes.session_path(conn, :login), @login_params)
      assert conn.resp_body =~ "The login was successful. Token: "
    end

    test "errors when trying to login twice", %{conn: conn} do
      assert {:ok, _account} = AccountInternal.register(@account_params)

      conn = post(conn, Routes.session_path(conn, :login), @login_params)
      assert conn.resp_body =~ "The login was successful. Token: "

      conn = post(conn, Routes.session_path(conn, :login), @login_params)
      assert conn.resp_body =~ "ERROR - reason: already_logged_in"
    end

    test "login an inexisting account", %{conn: conn} do
      conn =
        post(conn, Routes.session_path(conn, :login), %{"document" => 123, "password" => "123"})

      assert conn.resp_body == "ERROR - reason: account_not_found"
    end

    test "login with an incorrect password", %{conn: conn} do
      assert {:ok, _account} = AccountInternal.register(@account_params)

      conn =
        post(conn, Routes.session_path(conn, :login), %{
          "document" => @login_params["document"],
          "password" => "123"
        })

      assert conn.resp_body =~ "ERROR - reason: unauthorized"
    end
  end

  describe "logout endpoint/2" do
    test "sucessfully logout", %{conn: conn} do
      assert {:ok, _account} = AccountInternal.register(@account_params)

      conn = post(conn, Routes.session_path(conn, :login), @login_params)
      assert conn.resp_body =~ "The login was successful. Token: "

      conn = get(conn, Routes.session_path(conn, :logout), @login_params)
      assert conn.resp_body =~ "Logged out"
    end
  end

  describe "register endpoint/2" do
    test "sucesfully register account", %{conn: conn} do
      conn = post(conn, Routes.session_path(conn, :register), @account_params)
      assert conn.resp_body =~ "The account was created"
    end

    test "errors when trying to register with bad params", %{conn: conn} do
      conn =
        post(conn, Routes.session_path(conn, :register), %{"document" => 123, "password" => "123"})

      assert conn.resp_body =~ "ERROR - reason: "
    end
  end
end
