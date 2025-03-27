defmodule TodoWeb.TodoItemControllerTest do
  use TodoWeb.ConnCase

  import Todo.TasksFixtures

  @create_attrs %{description: "some description", title: "some title", due_date: ~D[2025-03-26], completed: true, created_at: ~U[2025-03-26 20:18:00Z], completed_at: ~U[2025-03-26 20:18:00Z]}
  @update_attrs %{description: "some updated description", title: "some updated title", due_date: ~D[2025-03-27], completed: false, created_at: ~U[2025-03-27 20:18:00Z], completed_at: ~U[2025-03-27 20:18:00Z]}
  @invalid_attrs %{description: nil, title: nil, due_date: nil, completed: nil, created_at: nil, completed_at: nil}

  describe "index" do
    test "lists all todos", %{conn: conn} do
      conn = get(conn, ~p"/todos")
      assert html_response(conn, 200) =~ "Listing Todos"
    end
  end

  describe "new todo_item" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/todos/new")
      assert html_response(conn, 200) =~ "New Todo item"
    end
  end

  describe "create todo_item" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/todos", todo_item: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/todos/#{id}"

      conn = get(conn, ~p"/todos/#{id}")
      assert html_response(conn, 200) =~ "Todo item #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/todos", todo_item: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Todo item"
    end
  end

  describe "edit todo_item" do
    setup [:create_todo_item]

    test "renders form for editing chosen todo_item", %{conn: conn, todo_item: todo_item} do
      conn = get(conn, ~p"/todos/#{todo_item}/edit")
      assert html_response(conn, 200) =~ "Edit Todo item"
    end
  end

  describe "update todo_item" do
    setup [:create_todo_item]

    test "redirects when data is valid", %{conn: conn, todo_item: todo_item} do
      conn = put(conn, ~p"/todos/#{todo_item}", todo_item: @update_attrs)
      assert redirected_to(conn) == ~p"/todos/#{todo_item}"

      conn = get(conn, ~p"/todos/#{todo_item}")
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, todo_item: todo_item} do
      conn = put(conn, ~p"/todos/#{todo_item}", todo_item: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Todo item"
    end
  end

  describe "delete todo_item" do
    setup [:create_todo_item]

    test "deletes chosen todo_item", %{conn: conn, todo_item: todo_item} do
      conn = delete(conn, ~p"/todos/#{todo_item}")
      assert redirected_to(conn) == ~p"/todos"

      assert_error_sent 404, fn ->
        get(conn, ~p"/todos/#{todo_item}")
      end
    end
  end

  defp create_todo_item(_) do
    todo_item = todo_item_fixture()
    %{todo_item: todo_item}
  end
end
