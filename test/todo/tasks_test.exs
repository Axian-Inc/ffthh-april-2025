defmodule Todo.TasksTest do
  use Todo.DataCase

  alias Todo.Tasks

  describe "todos" do
    alias Todo.Tasks.TodoItem

    import Todo.TasksFixtures

    @invalid_attrs %{description: nil, title: nil, due_date: nil, completed: nil, created_at: nil, completed_at: nil}

    test "list_todos/0 returns all todos" do
      todo_item = todo_item_fixture()
      assert Tasks.list_todos() == [todo_item]
    end

    test "get_todo_item!/1 returns the todo_item with given id" do
      todo_item = todo_item_fixture()
      assert Tasks.get_todo_item!(todo_item.id) == todo_item
    end

    test "create_todo_item/1 with valid data creates a todo_item" do
      valid_attrs = %{description: "some description", title: "some title", due_date: ~D[2025-03-26], completed: true, created_at: ~U[2025-03-26 20:18:00Z], completed_at: ~U[2025-03-26 20:18:00Z]}

      assert {:ok, %TodoItem{} = todo_item} = Tasks.create_todo_item(valid_attrs)
      assert todo_item.description == "some description"
      assert todo_item.title == "some title"
      assert todo_item.due_date == ~D[2025-03-26]
      assert todo_item.completed == true
      assert todo_item.created_at == ~U[2025-03-26 20:18:00Z]
      assert todo_item.completed_at == ~U[2025-03-26 20:18:00Z]
    end

    test "create_todo_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_todo_item(@invalid_attrs)
    end

    test "update_todo_item/2 with valid data updates the todo_item" do
      todo_item = todo_item_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", due_date: ~D[2025-03-27], completed: false, created_at: ~U[2025-03-27 20:18:00Z], completed_at: ~U[2025-03-27 20:18:00Z]}

      assert {:ok, %TodoItem{} = todo_item} = Tasks.update_todo_item(todo_item, update_attrs)
      assert todo_item.description == "some updated description"
      assert todo_item.title == "some updated title"
      assert todo_item.due_date == ~D[2025-03-27]
      assert todo_item.completed == false
      assert todo_item.created_at == ~U[2025-03-27 20:18:00Z]
      assert todo_item.completed_at == ~U[2025-03-27 20:18:00Z]
    end

    test "update_todo_item/2 with invalid data returns error changeset" do
      todo_item = todo_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_todo_item(todo_item, @invalid_attrs)
      assert todo_item == Tasks.get_todo_item!(todo_item.id)
    end

    test "delete_todo_item/1 deletes the todo_item" do
      todo_item = todo_item_fixture()
      assert {:ok, %TodoItem{}} = Tasks.delete_todo_item(todo_item)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_todo_item!(todo_item.id) end
    end

    test "change_todo_item/1 returns a todo_item changeset" do
      todo_item = todo_item_fixture()
      assert %Ecto.Changeset{} = Tasks.change_todo_item(todo_item)
    end
  end
end
