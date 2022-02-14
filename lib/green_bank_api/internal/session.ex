defmodule GreenBankApi.Internal.Session do
  @moduledoc """
    Módulo responsável por gerir a sessão do usuário.
    Operações incluidas: login, logout, verificação de token.
  """

  alias Ecto.Multi
  alias GreenBankApi.Internal.Account, as: AccountInternal
  alias GreenBankApi.Model.Session
  alias GreenBankApi.Repo

  import Ecto.Changeset

  @doc """
    Loga um usuário apartir de seu documento.

    Retorna erro caso a conta não exista, a senha esteja incorreta ou
    se o usuário já está logado.
  """
  def login(document, given_pass) do
    Multi.new()
    |> Multi.run(:get_account, fn _, _ ->
      verify_account(document)
    end)
    # Verifica a senha.
    |> Multi.run(:verify_pass, fn _, %{get_account: account} ->
      cond do
        Pbkdf2.verify_pass(given_pass, account.password_hash) ->
          {:ok, :authorized}

        account ->
          {:error, :unauthorized}

        true ->
          Pbkdf2.no_user_verify()
          {:error, :not_found}
      end
    end)
    # Checa se o usu[ario já está logado.
    |> Multi.run(:check_for_login_status, fn _, %{get_account: account} ->
      account_token = Repo.get_by(Session, account_id: account.account_id)

      if account_token == nil do
        {:ok, :not_logged_in}
      else
        {:error, :already_logged_in}
      end
    end)
    # Gera o token.
    |> Multi.run(:generate_token, fn _, %{get_account: account} ->
      # Exemplo de token: ea470e5763b$907ff1b40384d
      symbols = '0123456789abcdef@$'
      symbol_count = Enum.count(symbols)

      token =
        for _ <- 1..25, into: "", do: <<Enum.at(symbols, :crypto.rand_uniform(0, symbol_count))>>

      changeset = Session.changeset(%{token: token, account_id: account.account_id})

      {:ok, changeset}
    end)
    # Insere o token na DB.
    |> Multi.insert(:insert_token, fn %{generate_token: changeset} ->
      change(changeset)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{generate_token: changeset}} -> {:ok, changeset.changes.token}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  @doc """
    Desloga o usuário.
  """
  def logout(document) do
    Multi.new()
    |> Multi.run(:get_account, fn _, _ ->
      verify_account(document)
    end)
    # Verifica se o usuário está logado.
    |> Multi.run(:check_session, fn _, %{get_account: account} ->
      case Repo.get_by(Session, account_id: account.account_id) do
        nil -> {:error, :not_logged_in}
        session -> {:ok, session}
      end
    end)
    # Deleta a sessão do usuário.
    |> Multi.run(:delete_session, fn _, %{check_session: session} ->
      Repo.delete(session)

      {:ok, :logged_out}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, :logged_out}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  @doc """
    Verifica o token do usuário.
  """
  def check_token(document, token) do
    Multi.new()
    |> Multi.run(:get_account, fn _, _ ->
      verify_account(document)
    end)
    # Pega o token armazenado durante o login.
    |> Multi.run(:get_stored_token, fn _, %{get_account: account} ->
      case Repo.get_by(Session, account_id: account.account_id) do
        nil -> {:error, :not_logged_in}
        session -> {:ok, session.token}
      end
    end)
    # Compara o token armazenado com o disponibilizado.
    |> Multi.run(:check_token, fn _, %{get_stored_token: stored_token} ->
      if stored_token == token do
        {:ok, :authorized}
      else
        {:error, :not_authorized}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, :authorized}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  defp verify_account(account_document) do
    # Verifica se a conta existe.
    case AccountInternal.fetch_by_document(account_document) do
      nil -> {:error, :account_not_found}
      account -> {:ok, account}
    end
  end
end
