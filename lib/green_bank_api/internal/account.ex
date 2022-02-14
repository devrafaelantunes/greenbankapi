defmodule GreenBankApi.Internal.Account do
  @moduledoc """
    Módulo responsável por lidar com todas as operações relacionadas a conta do usuário.
  """
  import Ecto.Query

  alias GreenBankApi.Model.Account, as: AccountModel
  alias GreenBankApi.Repo

  @doc """
    Registra um usuário.

    A função espera receber um mapa com os seguintes parametros:
    - document: documento do usuário (CPF).  Formato: 00000000000
    - account_holder: email do usuário.
    - password: senha de no mínimo 7 digitos.
  """
  def register(params) do
    account_changeset = AccountModel.create_changeset(params)

    case Repo.insert(account_changeset) do
      # Valida se a inserção é válida ou não.
      {:ok, changeset} -> {:ok, changeset}
      {:error, changeset} -> {:error, changeset_error_to_string(changeset)}
    end
  end

  defp changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k} field: #{joined_errors}\n"
    end)
  end

  @doc """
    Essa função é responsável por gerar um número aleatório entre 000 a 9999 que será
    utilizado como o número da conta.
    
    Se caso uma conta com o número gerado já exista, a função se repetirá até encontrar um número
    disponível.

    Possíveis problemas:
    - Escabilidade (conforme o banco cresce, uma hora podemos não ter mais números disponíveis)
    - Recursão (várias queries dependendo dos números gerados)

    Este é um ponto que deverá ser repensado e melhorado em um possível code refactor.
  """
  def generate_account_number() do
    account_number = Enum.random(0000..9999)

    if account_number_already_exists?(account_number) do
      generate_account_number()
    else
      account_number
    end
  end

  defp account_number_already_exists?(account_number) do
    Repo.exists?(from a in "account", where: a.account_number == ^account_number)
  end

  @doc """
    Retorna uma conta através de seu documento. Retorna nil caso inválida ou ienxistente.
  """
  def fetch_by_document(document_number), do: Repo.get_by(AccountModel, document: document_number)

  @doc """
    Retorna o saldo do usuário se a conta for válida.
  """
  def get_balance(document_number) do
    case fetch_by_document(document_number) do
      nil -> {:error, :account_not_found}
      account -> {:ok, account.balance}
    end
  end
end
