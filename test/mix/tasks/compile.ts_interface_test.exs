defmodule Mix.RouterTest do
  use Phoenix.Router
  get("/", PageController, :index, as: :page)
  resources("/users", UserController)

  scope "/api" do
    get("/products", ProductController, :index)
    put("/orders/:id", OrderController, :update)
    resources("/admin", AdminController)
  end
end

defmodule Mix.Tasks.Compile.TsInterfaceTest do
  use ExUnit.Case, async: false
  use TestFolderSupport

  import TestHelper

  @tag :clean_folder
  test "allows to configure the output path", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      Mix.Tasks.Compile.TsInterface.run(["--router", "Mix.RouterTest"])
      assert_file(path(folder, "phoenix_ts_interface.ts"))
    end)
  end

  test "generates a valid ts module" do
    run_with_env([output_folder: "tmp"], fn ->
      Mix.Tasks.Compile.TsInterface.run(["--router", "Mix.RouterTest"])
      assert_file("tmp/phoenix_ts_interface.ts")

      # run typescript compiler
      assert {_, 0} = System.cmd("npm", ["run", "compile"])
      # run typescript tests
      assert {_, 0} = System.cmd("npm", ["test"])

      throw("not impl")
    end)
  end

  @tag :clean_folder
  test "ignore the first argument when it is not a valid module name", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      assert_raise(Mix.Error, "module Elixir.NotFound was not loaded and cannot be loaded", fn ->
        Mix.Tasks.Compile.TsInterface.run(["--router", "NotFound"])
      end)
    end)
  end

  @tag :clean_folder
  test "allows to filter urls", %{folder: folder} do
    run_with_env([output_folder: folder, include: ~r[api/], exclude: ~r[/admin]], fn ->
      Mix.Tasks.Compile.TsInterface.run(["--router", "Mix.RouterTest"])

      assert_contents(path(folder, "phoenix_ts_interface.ts"), fn file ->
        refute file =~ "page"
        refute file =~ "user"
        refute file =~ "admin"

        assert file =~ "productIndex() {"
        assert file =~ "return '/api/products';"

        assert file =~ "orderUpdate(id) {"
        assert file =~ "return '/api/orders/' + id;"
      end)
    end)
  end

  @tag :clean_folder
  test "clean up compilation artifacts", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      Mix.Tasks.Compile.TsInterface.run(["--router", "Mix.RouterTest"])
      assert_file(path(folder, "phoenix_ts_interface.ts"))
      Mix.Tasks.Compile.TsInterface.clean()
      refute_file(path(folder, "phoenix_ts_interface.ts"))
    end)
  end

  @tag :clean_folder
  test "forces compilation", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      Mix.Tasks.Compile.TsInterface.run(["--router", "Mix.RouterTest"])
      File.rm(path(folder, "phoenix_ts_interface.ts"))
      Mix.Tasks.Compile.TsInterface.run(["--router", "Mix.RouterTest", "--force"])
      assert_file(path(folder, "phoenix_ts_interface.ts"))
    end)
  end

  defp run_with_env(env, fun) do
    try do
      Application.put_env(:phoenix_ts_interface, :ts_interface, env)
      fun.()
    after
      Application.put_env(:phoenix_ts_interface, :ts_interface, nil)
    end
  end
end
