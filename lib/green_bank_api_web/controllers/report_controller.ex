defmodule GreenBankApiWeb.ReportController do
  @moduledoc """
    Controller responsável por lidar com as requisições relacionadas a relatórios.
  """

  use GreenBankApiWeb, :controller

  alias GreenBankApi.Internal.Report, as: Report

  plug GreenBankApiWeb.Plug.Session

  @doc """
    Retorna o total transacionado em R$ em um determinado período.

    Para ver o relatorio baseado em um ano: definir o year e deixar month e day como nil.
    Para ver o relatorio baseado em um mês especifico: definir o year e o month, deixar day como nil.
    Para ver o relatório baseado em um dia especifico: definir o year, month e day.
    Para ver o relatório total: deixar todos como nil. (year, month, day).

    GET REQUEST portanto é necessário enviar os parametros por uma query string.
  """
  def create(conn, params) do
    generate_report(conn, %{year: params["year"], month: params["month"], day: params["day"]})
  end

  # Report do total transacionado no banco em todos os periodos.
  defp generate_report(conn, %{day: "nil", month: "nil", year: "nil"}) do
    report = Report.generate()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      201,
      "The total transactioned is R$#{report}"
    )
  end

  # Report anual.
  defp generate_report(conn, %{day: "nil", month: "nil", year: year}) do
    {low_date, high_date} = Report.calculate_low_high_date(year, nil, nil)

    report = Report.generate(low_date, high_date)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      201,
      "The total transactioned between #{low_date} and #{high_date} - R$#{report}"
    )
  end

  # Report mensal.
  defp generate_report(conn, %{year: year, month: month, day: "nil"}) do
    # Força um padrão no input dos meses. (2 algarismos)
    # Janeiro por exemplo será 01, Fevereiro 02... 
    month = String.pad_leading(month, 2, "0")

    {low_date, high_date} = Report.calculate_low_high_date(year, month, nil)

    report = Report.generate(low_date, high_date)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      201,
      "The total transactioned between #{low_date} and #{high_date} - R$#{report}"
    )
  end

  # Report de um dia especifico.
  defp generate_report(conn, %{year: year, month: month, day: day}) do
    month = String.pad_leading(month, 2, "0")
    day = String.pad_leading(day, 2, "0")

    {low_date, high_date} = Report.calculate_low_high_date(year, month, day)

    report = Report.generate(low_date, high_date)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      201,
      "The total transactioned between #{low_date} and #{high_date} - R$#{report}"
    )
  end
end
