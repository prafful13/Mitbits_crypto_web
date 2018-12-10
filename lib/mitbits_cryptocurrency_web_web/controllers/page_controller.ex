defmodule MitbitsCryptocurrencyWebWeb.PageController do
  use MitbitsCryptocurrencyWebWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
