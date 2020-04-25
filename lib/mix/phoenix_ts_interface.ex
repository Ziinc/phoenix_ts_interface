defmodule PhoenixTsInterface do
  @doc """
  Fetches the return types from the controller.

  The controller specs should reference relevant views as return types

  The first tuple position is the function name

  The second tuple position is the input types

  The third tuple position is the output types


  For example, takes a map with the "id" key and a string value, and outputs a map with the "value" key as a string
  iex> get_route_return_types(route)
  [
    {:index,  }
  ]

  """
  def get_route_return_types(route) do
    {:ok, specs} = Code.Typespec.fetch_specs(route.plug)
    # ExDoc.Retriever.docs_from_modules([route.plug], %ExDoc.Config{})
    # Introspection.t({, route.plug_opts, 2})
    specs
    |> IO.inspect()
  end

  @spec function_name(%{helper: any}) :: binary
  def function_name(%{helper: helper, opts: opts}) do
    "#{helper}_#{opts}" |> Macro.camelize() |> downcase_first
  end

  def function_name(%{helper: helper, plug_opts: opts}) do
    "#{helper}_#{opts}" |> Macro.camelize() |> downcase_first
  end

  defp downcase_first(<<first::utf8, rest::binary>>) do
    String.downcase(<<first>>) <> rest
  end

  def function_params(%{path: path}) do
    String.split(path, "/")
    |> Enum.filter(&String.starts_with?(&1, ":"))
    |> Enum.join(", ")
    |> String.replace(":", "")
  end

  def function_body(%{path: path}) do
    PhoenixTsInterface.UrlTransformer.to_js(path)
  end

  # just for tests, so we can run the task in this project.
  # Should go away in the future
  defmodule Router do
    def __routes__ do
      [
        %{helper: "user", opts: :create, path: "/users"},
        %{helper: "user", opts: :update, path: "/users/:id"},
        %{helper: "user_friends", opts: :create, path: "/users/:user_id/friends"},
        %{helper: "user_friends", opts: :update, path: "/users/:user_id/friends/:id"},
        %{helper: "user_friends", opts: :delete, path: "/users/:user_id/friends/:id"}
      ]
    end
  end
end
