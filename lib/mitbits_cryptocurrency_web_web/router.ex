defmodule MitbitsCryptocurrencyWebWeb.Router do
  use MitbitsCryptocurrencyWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MitbitsCryptocurrencyWebWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/hello", HelloController, :index
    get "/hello/:messenger", HelloController, :show

  end

  # Other scopes may use custom stacks.
  # scope "/api", MitbitsCryptocurrencyWebWeb do
  #   pipe_through :api
  # end
end
