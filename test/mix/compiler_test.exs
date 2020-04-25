defmodule Mix.Compilers.Phoenix.TsInterface.RouterTest do
  use Phoenix.Router
  get("/", PageController, :index, as: :page)
  resources("/users", UserController)

  scope "/api" do
    get("/products", ProductController, :index)
    put("/orders/:id", OrderController, :update)
  end
end

defmodule Mix.Compilers.Phoenix.TsInterfaceTest do
  use ExUnit.Case, async: false
  use TestFolderSupport

  import TestHelper

  alias Mix.Compilers.Phoenix.TsInterface.RouterTest

  @manifest "_build/test/lib/phoenix_ts_interface/compile.ts_interface"

  setup do
    on_exit(fn ->
      File.rm(@manifest)
    end)
  end

  @tag :clean_folder
  test "fires the callback and writes the manifest", %{folder: folder} do
    assert :ok = compile({RouterTest, Path.join(folder, "test_requests.ts")})
    assert_file(@manifest)
  end

  @tag :clean_folder
  test "return :noop when there's no change", %{folder: folder} do
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    assert :noop = compile({RouterTest, path(folder, "test_requests.ts")})
  end

  @tag :clean_folder
  test "forces compilation to run", %{folder: folder} do
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")}, true)
  end

  @tag :clean_folder
  test "fires again when the module code changes", %{folder: folder} do
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    redefine_module!()
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
  end

  @tag :clean_folder
  test "fires the callback for every module in the mappings", %{folder: folder} do
    mappings = [
      {RouterTest, path(folder, "test_requests.ts")},
      {Elixir.Atom, path(folder, "atom.ts")},
      {Elixir.Agent, path(folder, "agent.ts")}
    ]

    {:ok, agent} = Agent.start_link(fn -> 0 end)

    assert :ok =
             Mix.Compilers.Phoenix.TsInterface.compile(@manifest, mappings, false, fn module,
                                                                                      output ->
               idx = Agent.get_and_update(agent, fn call -> {call, call + 1} end)
               {expected_module, expected_out} = Enum.fetch!(mappings, idx)
               assert expected_module == module
               assert expected_out == output
               :ok
             end)

    assert Agent.get(agent, fn call -> call end) == 3
    Agent.stop(agent)
  end

  @tag :clean_folder
  test "keeps the manifest up to date", %{folder: folder} do
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    redefine_module!()
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    entries = Mix.Compilers.Phoenix.TsInterface.read_manifest(@manifest)
    assert length(entries) == 1
    new_hash = RouterTest.module_info()[:md5]
    expected_path = path(folder, "test_requests.ts")
    assert {RouterTest, ^new_hash, ^expected_path} = Enum.fetch!(entries, 0)
  end

  @tag :clean_folder
  test "remove outputs that are not in the mappings anymore", %{folder: folder} do
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    assert :ok = compile({RouterTest, path(folder, "teste-routes-new.js")})
    refute_file(path(folder, "test_requests.ts"))
    entries = Mix.Compilers.Phoenix.TsInterface.read_manifest(@manifest)
    assert length(entries) == 1
    expected_path = path(folder, "teste-routes-new.js")
    assert {RouterTest, _, ^expected_path} = Enum.fetch!(entries, 0)
  end

  @tag :clean_folder
  test "remove modules that are not in the mappings anymore", %{folder: folder} do
    assert :ok = compile({RouterTest, path(folder, "test_requests.ts")})
    assert :ok = compile({Elixir.Agent, path(folder, "agent.ts")})
    refute_file(path(folder, "test_requests.ts"))
    entries = Mix.Compilers.Phoenix.TsInterface.read_manifest(@manifest)
    assert length(entries) == 1
    expected_path = path(folder, "agent.ts")
    assert {Elixir.Agent, _, ^expected_path} = Enum.fetch!(entries, 0)
  end

  @tag :clean_folder
  test "clean up compilation artifacts", %{folder: folder} do
    assert :ok =
             compile([
               {RouterTest, path(folder, "test_requests.ts")},
               {Elixir.Agent, path(folder, "agent.ts")}
             ])

    Mix.Compilers.Phoenix.TsInterface.clean(@manifest)
    refute_file(path(folder, "test_requests.ts"))
    refute_file(path(folder, "agent.ts"))
  end

  defp compile(mappings, force \\ false)
  defp compile(mapping = {_, _}, force), do: compile([mapping], force)

  defp compile(mappings, force) do
    Mix.Compilers.Phoenix.TsInterface.compile(@manifest, mappings, force, fn module, out ->
      File.write(out, module |> to_string)
    end)
  end

  defp redefine_module! do
    Code.compile_quoted(
      quote do
        defmodule Mix.Compilers.Phoenix.TsInterface.RouterTest do
          # Always define a new function name to force the module's hash to change
          def unquote(:"a_#{unique_id}")(), do: "test"
        end
      end
    )
  end
end
