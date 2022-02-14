defmodule GreenBankApi.Internal.Transaction do
  @moduledoc """
    Módulo responsável por realizar todas as transações disponíveis no banco.
    
    Todas as operações acontecem dentro do Ecto.Multi, em uma única transação.
    Caso algum erro aconteça, a transação sofrerá um rollback.
    Impedindo assim, quaisquer efeitos colaterais.
  """

  alias Ecto.Multi
  alias GreenBankApi.Repo
  alias GreenBankApi.Internal.Account, as: AccountInternal
  alias GreenBankApi.Model.Transaction
  alias GreenBankApi.Utils.Decimal, as: DecimalUtils

  require Logger

  import Ecto.Changeset

  @doc """
    Cria e realiza uma transação baseada em seu tipo.

    A função espera um mapa com os seguintes parametros:
    - transaction_type: tipo da transação.
      * saque: withdraw.
      * deposito: deposit.
      * wire_transfer: transferência.
    - payer: conta principal.
    - payee: conta destino. (somente necessário, se a transação for uma transferência).
    - amount: valor da transação.
  """
  def create(params) do
    case Map.get(params, "transaction_type") do
      "withdraw" -> validate_withdraw(params)
      "deposit" -> validate_deposit(params)
      "wire_transfer" -> validate_wire_transfer(params)
      _ -> {:error, :transaction_not_found}
    end
  end

  @doc """
    Função que valida e realiza um saque.
    Antes de realizar o saque, a transação passará por algumas verificações, tais como:

    - Se a conta realmente existe.
    - Se a conta possui saldo suficiente para o saldo.
    - Saldo mínimo em conta: 0.
  """
  defp validate_withdraw(params) do
    changeset = Transaction.create_changeset(params)

    Multi.new()
    |> Multi.run(:get_account, fn _, _ ->
      verify_account(Map.get(params, "payer"))
    end)
    |> Multi.run(:check_balance, fn _, %{get_account: account} ->
      verify_balance(account, Map.get(params, "amount"))
    end)
    |> Multi.update(:update_balance, fn %{get_account: account} ->
      update_balance("sub", account, Map.get(params, "amount"))
    end)
    |> Multi.insert(:insert_transaction, changeset)
    |> Multi.update(:insert_transaction_date, fn %{insert_transaction: transaction} ->
      insert_transaction_date(transaction)
    end)
    |> Multi.run(:send_email_to_account_holder, fn _, %{get_account: account} ->
      send_email_to_account_holder(account)
    end)
    # Realiza a transação.
    |> Repo.serializable_transaction()
  end

  @doc """
    Função que valida e realiza um deposito.
    Antes de realizar o deposito, a função verifica se a conta realmente existe.
  """
  defp validate_deposit(params) do
    changeset = Transaction.create_changeset(params)

    Multi.new()
    |> Multi.run(:get_account, fn _, _ ->
      verify_account(Map.get(params, "payer"))
    end)
    |> Multi.update(:update_balance, fn %{get_account: account} ->
      update_balance("add", account, Map.get(params, "amount"))
    end)
    |> Multi.insert(:insert_transaction, changeset)
    |> Multi.update(:insert_transaction_date, fn %{insert_transaction: transaction} ->
      insert_transaction_date(transaction)
    end)
    |> Multi.run(:send_email_to_account_holder, fn _, %{get_account: account} ->
      send_email_to_account_holder(account)
    end)
    # Realiza a transação.
    |> Repo.serializable_transaction()
  end

  @doc """
    Função que valida e realiza uma transferência entre contas.
    Antes de realizar a transferência, a transação passará por algumas verificações, tais como:

    - Se ambas as contas realmente existem.
    - Se a conta que está realizando a transferência possui saldo suficiente para completar a transação.
    - Saldo mínimo em conta: 0.
  """
  defp validate_wire_transfer(params) do
    changeset = Transaction.create_changeset(params)

    Multi.new()
    |> Multi.run(:get_payer_account, fn _, _ ->
      verify_account(Map.get(params, "payer"))
    end)
    |> Multi.run(:get_payee_account, fn _, _ ->
      verify_account(Map.get(params, "payee"))
    end)
    |> Multi.run(:check_payer_balance, fn _, %{get_payer_account: account} ->
      verify_balance(account, Map.get(params, "amount"))
    end)
    # Atualiza ambas as contas
    |> Multi.update(:update_payer_balance, fn %{get_payer_account: account} ->
      update_balance("sub", account, Map.get(params, "amount"))
    end)
    |> Multi.update(:update_payee_balance, fn %{get_payee_account: account} ->
      update_balance("add", account, Map.get(params, "amount"))
    end)
    |> Multi.insert(:insert_transaction, changeset)
    |> Multi.update(:insert_transaction_date, fn %{insert_transaction: transaction} ->
      insert_transaction_date(transaction)
    end)
    |> Multi.run(:send_email_to_payer, fn _, %{get_payer_account: account} ->
      send_email_to_account_holder(account)
    end)
    |> Multi.run(:send_email_to_payee, fn _, %{get_payee_account: account} ->
      send_email_to_account_holder(account)
    end)
    # Realiza a transação.
    |> Repo.serializable_transaction()
  end

  defp verify_account(account_document) do
    # Verifica se a conta existe.
    case AccountInternal.fetch_by_document(account_document) do
      nil -> {:error, :account_not_found}
      account -> {:ok, account}
    end
  end

  defp verify_balance(account, transaction_amount) do
    # Verifica o saldo em conta.
    if DecimalUtils.gte?(account.balance, transaction_amount) do
      {:ok, account}
    else
      {:error, :not_enough_funds}
    end
  end

  defp update_balance(transaction_type, account, transaction_amount) do
    # Atualiza o saldo em conta baseada no tipo de transação.
    # "sub" para operações de retirada de dinheiro.
    # "add" para operações de adição de dinheiro.
    new_balance =
      case transaction_type do
        "sub" -> Decimal.sub(account.balance, transaction_amount)
        "add" -> Decimal.add(account.balance, transaction_amount)
      end

    change(account, balance: new_balance)
  end

  defp send_email_to_account_holder(account) do
    # Simulação de um envio de email para o account holder notificando-o da transação.
    Logger.info("The email was sent to: #{account.account_holder}")

    {:ok, :email_sent}
  end

  defp insert_transaction_date(transaction) do
    # UTC Datetime sem millisegundos
    utc_datetime_now = DateTime.utc_now() |> DateTime.truncate(:second)

    change(transaction, transaction_datetime: utc_datetime_now)
  end
end
