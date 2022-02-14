{application,green_bank_api,
             [{applications,[kernel,stdlib,elixir,guardian,logger,
                             runtime_tools,phoenix,decimal,phoenix_ecto,
                             ecto_sql,postgrex,phoenix_live_dashboard,swoosh,
                             telemetry_metrics,telemetry_poller,gettext,jason,
                             plug_cowboy,pbkdf2_elixir]},
              {description,"green_bank_api"},
              {modules,['Elixir.GreenBankApi.Application',
                        'Elixir.GreenBankApi.Internal.Account',
                        'Elixir.GreenBankApi.Internal.Report',
                        'Elixir.GreenBankApi.Internal.Session',
                        'Elixir.GreenBankApi.Internal.Transaction',
                        'Elixir.GreenBankApi.Model.Account',
                        'Elixir.GreenBankApi.Model.Session',
                        'Elixir.GreenBankApi.Model.Transaction',
                        'Elixir.GreenBankApi.Release',
                        'Elixir.GreenBankApi.Repo',
                        'Elixir.GreenBankApi.Utils.Decimal',
                        'Elixir.GreenBankApiWeb',
                        'Elixir.GreenBankApiWeb.Endpoint',
                        'Elixir.GreenBankApiWeb.ErrorHelpers',
                        'Elixir.GreenBankApiWeb.ErrorView',
                        'Elixir.GreenBankApiWeb.Gettext',
                        'Elixir.GreenBankApiWeb.Plug.Session',
                        'Elixir.GreenBankApiWeb.ReportController',
                        'Elixir.GreenBankApiWeb.Router',
                        'Elixir.GreenBankApiWeb.Router.Helpers',
                        'Elixir.GreenBankApiWeb.SessionController',
                        'Elixir.GreenBankApiWeb.Telemetry',
                        'Elixir.GreenBankApiWeb.TransactionController']},
              {registered,[]},
              {vsn,"0.1.0"},
              {mod,{'Elixir.GreenBankApi.Application',[]}}]}.