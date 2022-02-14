defmodule GreenBankApi.Utils.Decimal do
  @moduledoc """
    Compara dois números decimais.
    Retorna true caso A seja maior ou igual a B.
    Retorna falso caso contrário.
  """
  def gte?(a, b), do: Decimal.gt?(a, b) or Decimal.eq?(a, b)
end
