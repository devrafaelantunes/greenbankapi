defmodule GreenBankApi.Internal.Report do
  @moduledoc """
    Módulo responsável por criar relatórios baseados nas transações realizadas por período.
  """

  import Ecto.Query
  alias GreenBankApi.Repo
  alias GreenBankApi.Model.Transaction

  @doc """
    Retorna o valor somado das transações realizadas em um período especifico.
    A query é feitas baseadas em duas datas:

    - low and high date.

    Se o usuário escolher um report baseado em um dia, a low date será no inicio daquele dia e a high date em seu final.
    Se ele escolher baseado em um mês, a low date será o seu primeiro dia e a high date o último.
    Já se for baseado em um ano, a low date será o primeiro mês do ano, e a high date o último.
  """
  def generate(low_date, high_date) do
    from(
      t in Transaction,
      where: t.transaction_datetime >= ^low_date,
      where: t.transaction_datetime <= ^high_date,
      select: fragment("COALESCE(SUM(?), 0.0)", t.amount)
    )
    |> Repo.one()
  end

  @doc """
    Se caso a função generate report não receber nenhum parametro, ela irá
    retornar o valor somado de todas as transações realizadas.
  """
  def generate() do
    from(
      t in Transaction,
      select: fragment("COALESCE(SUM(?), 0.0)", t.amount)
    )
    |> Repo.one()
  end

  @doc """
    Funções responsáveis por calcular a high and low date.

    Report baseado em um ano.
  """
  def calculate_low_high_date(year, nil, nil) do
    {:ok, low_date, _} = DateTime.from_iso8601("#{year}-01-01T00:00:00Z")
    {:ok, high_date, _} = DateTime.from_iso8601("#{year}-12-31T23:59:59Z")

    {low_date, high_date}
  end

  # Report baseado em um mes especifico.
  def calculate_low_high_date(year, month, nil) do
    # Pega o último dia do mês.
    last_day_of_the_month =
      :calendar.last_day_of_the_month(String.to_integer(year), String.to_integer(month))

    # Cria um %DateTime{} baseado em uma string.
    {:ok, low_date, _} = DateTime.from_iso8601("#{year}-#{month}-01T00:00:00Z")

    {:ok, high_date, _} =
      DateTime.from_iso8601("#{year}-#{month}-#{last_day_of_the_month}T23:59:59Z")

    {low_date, high_date}
  end

  # Report baseado em um dia especifico.
  def calculate_low_high_date(year, month, day) do
    {:ok, low_date, _} = DateTime.from_iso8601("#{year}-#{month}-#{day}T00:00:00Z")
    {:ok, high_date, _} = DateTime.from_iso8601("#{year}-#{month}-#{day}T23:59:59Z")

    {low_date, high_date}
  end
end
