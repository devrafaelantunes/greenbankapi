defmodule GreenBankApiWeb.Router do
  use GreenBankApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", GreenBankApiWeb do
    pipe_through :api

    post "/login", SessionController, :login
    post "/register", SessionController, :register
    get "/logout", SessionController, :logout

    # Somente com token válidos é possível acessar os endpoints abaixo:
    post "/transaction", TransactionController, :create
    get "/report", ReportController, :create
  end
end
