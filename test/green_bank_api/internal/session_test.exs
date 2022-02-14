defmodule GreenBankApi.Internal.SessionTest do
  use ExUnit.Case, async: true

  alias GreenBankApi.Repo
  alias GreenBankApi.Internal.Session, as: SessionInternal
  alias GreenBankApi.Internal.Account, as: AccountInternal
  alias GreenBankApi.Model.Session, as: SessionModel

  @account_params %{
    "document" => 12_151_194_884,
    "account_holder" => "jose@hotmail.com",
    "password" => "1234567"
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, account} = AccountInternal.register(@account_params)

    {:ok, %{account: account}}
  end

  describe "login/2" do
    test "with correct document and password", %{account: account} do
      # Realiza o login.
      {:ok, token} = SessionInternal.login(account.document, account.password)

      # Extrai a sessão relacionada com o usuário.
      session = Repo.get_by(SessionModel, account_id: account.account_id)

      # Compara ambos tokens.
      assert token == session.token
    end

    test "with incorrect password", %{account: account} do
      {:error, reason} = SessionInternal.login(account.document, "123")

      session = Repo.get_by(SessionModel, account_id: account.account_id)

      assert reason == :unauthorized
      assert session == nil
    end

    test "with incorrect document", %{account: account} do
      {:error, reason} = SessionInternal.login(430_213, account.password)

      session = Repo.get_by(SessionModel, account_id: account.account_id)

      assert reason == :account_not_found
      assert session == nil
    end

    test "login with the same account twice", %{account: account} do
      {:ok, token} = SessionInternal.login(account.document, account.password)

      session = Repo.get_by(SessionModel, account_id: account.account_id)
      assert token == session.token

      # Realiza o login novamente, recebendo um erro dessa vez.
      {:error, reason} = SessionInternal.login(account.document, account.password)
      assert reason == :already_logged_in

      # Não houve mudança no token da sessão.
      session = Repo.get_by(SessionModel, account_id: account.account_id)
      assert token == session.token
    end
  end

  describe "logout/1" do
    test "sucessfully logout", %{account: account} do
      {:ok, token} = SessionInternal.login(account.document, account.password)

      session = Repo.get_by(SessionModel, account_id: account.account_id)

      assert token == session.token

      assert {:ok, :logged_out} == SessionInternal.logout(account.document)

      # Confirma se a sessão foi apagada
      assert Repo.get_by(SessionModel, account_id: account.account_id) == nil
    end

    test "without an active session", %{account: account} do
      assert Repo.get_by(SessionModel, account_id: account.account_id) == nil

      assert {:error, :not_logged_in} = SessionInternal.logout(account.document)
    end
  end

  describe "check_token" do
    test "check a valid token", %{account: account} do
      {:ok, token} = SessionInternal.login(account.document, account.password)

      assert {:ok, :authorized} = SessionInternal.check_token(account.document, token)
    end

    test "check an invalid token", %{account: account} do
      {:ok, _token} = SessionInternal.login(account.document, account.password)

      assert {:error, :not_authorized} = SessionInternal.check_token(account.document, "123")
    end
  end
end
