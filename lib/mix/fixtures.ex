defmodule PhoenixTsInterface.Controller do
  @doc """
  Only for testing purposes
  """
  @spec index(Plug.Conn.t(), %{id: String.t()}) :: PhoenixTsInterface.View.test()
  def index(conn, _) do
    conn
    |> Phoenix.Controller.put_view(PhoenixTsInterfaceTestView)
    |> Phoenix.Controller.render("test.json")
  end
end

defmodule PhoenixTsInterface.View do
  @doc """
  Only for testing purposes
  """
  @type test() :: %{
          value: String.t()
        }
  def render("test.json", assigns) do
    assigns
  end
end
