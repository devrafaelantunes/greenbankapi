defmodule GreenBankApi.Model.Account do
  @moduledoc """
    Model criada para armazenar as contas dos usuários no banco.
  """

  alias GreenBankApi.Internal.Account, as: AccountInternal
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:account_id, :id, autogenerate: true}
  schema "account" do
    field :document, :integer
    field :account_holder, :string

    # Nosso banco possui apenas uma agência, portanto, todas as contas
    # compartilham o mesmo número.
    field :branch_number, :integer, default: 1
    field :account_number, :integer
    # Todo usuário começa com 1000.00 de saldo.
    field :balance, :decimal, default: Decimal.new(1000)

    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def create_changeset(params) do
    # Gera e insere o número da conta dentro dos parametros.
    params = Map.put(params, "account_number", AccountInternal.generate_account_number())

    %__MODULE__{}
    |> cast(params, [:document, :account_holder, :password, :account_number])
    |> validate_required([:document, :account_holder, :password])
    |> validate_format(:account_holder, ~r/@/)
    |> validate_length(:password, min: 7, max: 40)
    |> validate_document(:document)
    |> unique_constraint([:document])
    |> put_pass_hash()
  end

  @doc """
    Efetua uma simples validação do documento CPF do usuário.
  """
  defp validate_document(changeset, document) do
    validate_change(changeset, document, fn field, doc_number ->
      if check_document_veracity(doc_number) do
        []
      else
        [{field, "is not valid"}]
      end
    end)
  end

  @doc """
    Para ser válido, um CPF precisa ter 11 dígitos numéricos e a sua soma
    precisa ser sempre um número de dois digitos iguais, ex: 22, 33, 44.. excluindo o número 11,
    e até no máximo 88.

    Essa função é responsável por realizar ambas verificações.

    Fonte: http://www.profcardy.com/cardicas/cpf-curiosidades.php

    Esse seria um ponto de melhoria em um próximo refactor.
  """
  defp check_document_veracity(doc_number) do
    length_doc_number =
      doc_number
      |> Integer.digits()
      |> length()

    if length_doc_number == 11 do
      # As possíveis somas de um CPF válido.
      valid_sum = [22, 33, 44, 55, 66, 77, 88]

      sum_doc_number =
        doc_number
        |> Integer.digits()
        |> Enum.sum()

      Enum.member?(valid_sum, sum_doc_number)
    end
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
