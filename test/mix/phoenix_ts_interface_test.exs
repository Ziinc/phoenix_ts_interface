defmodule PhoenixTsInterfaceTest do
  use ExUnit.Case

  import PhoenixTsInterface

  @valid_route %Phoenix.Router.Route{
    assigns: %{},
    helper: "page",
    host: nil,
    kind: :match,
    line: 3,
    metadata: %{log: :debug},
    path: "/",
    pipe_through: [],
    plug: PhoenixTsInterface.Controller,
    plug_opts: :index,
    private: %{},
    trailing_slash?: false,
    verb: :get
  }
  @invalid_route %Phoenix.Router.Route{
    assigns: %{},
    helper: "user",
    host: nil,
    kind: :match,
    line: 2,
    metadata: %{log: :debug},
    path: "/",
    pipe_through: [],
    plug: PhoenixTsInterface.Controller,
    plug_opts: :index,
    private: %{},
    trailing_slash?: false,
    verb: :get
  }

  test "get_route_return_types returns the types of controller route" do
    get_route_return_types(@valid_route)

    assert false
  end

  test "function_name returns the camelized js function name" do
    assert function_name(%{helper: "user", opts: :create}) == "userCreate"
    assert function_name(%{helper: "user_friends", opts: :update}) == "userFriendsUpdate"
    assert function_name(%{helper: "User_friends", opts: :delete}) == "userFriendsDelete"
  end

  test "function_params returns the list of params" do
    assert function_params(%{path: "/users"}) == ""
    assert function_params(%{path: "/users/:id"}) == "id"
    assert function_params(%{path: "/users/:user_id/friends/:id"}) == "user_id, id"
    assert function_params(%{path: "/users/:user_id/:id"}) == "user_id, id"
  end

  test "function_body returns a valid javascript expression with an url" do
    assert function_body(%{path: "/users"}) == "'/users'"
    assert function_body(%{path: "/users/:id"}) == "'/users/' + id"
    assert function_body(%{path: "/users/:foo/:bar"}) == "'/users/' + foo + '/' + bar"
    assert function_body(%{path: "/users/:user_id/friends"}) == "'/users/' + user_id + '/friends'"

    assert function_body(%{path: "/users/:user_id/friends/:id"}) ==
             "'/users/' + user_id + '/friends/' + id"
  end
end
