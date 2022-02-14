defmodule GreenBankApiWeb.SessionController do
  @moduledoc """
    Controller responsável por lidar com as requisições relacionadas a registro, login e logout.
  """

  use GreenBankApiWeb, :controller

  alias GreenBankApi.Internal.Account, as: AccountInternal
  alias GreenBankApi.Internal.Session, as: SessionInternal

  @doc """
    Registra o usuário.

    Exemplo de parametros (JSON):
      {
      "document": "12151194884",
      "account_holder": "rafa@live.com",
      "password": "1234567"
      } 
  """
  def register(conn, params) do
    case AccountInternal.register(params) do
      {:ok, _changeset} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, "The account was created.")

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, "ERROR - reason: #{reason}")
    end
  end

  @doc """
    Loga o usuário.

    Exemplo de parametros (JSON):
      {
      "document": "43082810837",
      "password": "1234567"
      } 
  """
  def login(conn, %{"document" => document, "password" => password}) do
    case SessionInternal.login(document, password) do
      {:ok, token} ->
        conn
        |> put_resp_content_type("application/json")
        |> assign(:token, token)
        |> send_resp(202, "The login was successful. Token: #{token}")

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, "ERROR - reason: #{reason}")
    end
  end

  # Pattern match para parametros fora do escopo.
  def login(conn, params) do
    conn
    |> send_resp(422, "wrong params")
    |> halt()
  end

  @doc """
    Desloga o usuário.

    Por ser um request GET, é necessário passar o documento por uma query string.
  """
  def logout(conn, %{"document" => document}) do
    case SessionInternal.logout(document) do
      {:ok, :logged_out} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, "Logged out")

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(417, "ERROR - reason: #{reason}")
    end
  end
end
