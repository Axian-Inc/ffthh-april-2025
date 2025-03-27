defmodule TodoWeb.TodoItemController do
  use TodoWeb, :controller

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  def index(conn, _params) do
    user_id = conn.assigns.current_user.id
    todos = Tasks.list_todos(user_id)
    render(conn, :index, todos: todos)
  end

  def new(conn, _params) do
    changeset = Tasks.change_todo_item(%TodoItem{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"todo_item" => todo_item_params}) do
    user_id = conn.assigns.current_user.id
    todo_item_params = Map.put(todo_item_params, "user_id", user_id)
    
    case Tasks.create_todo_item(todo_item_params) do
      {:ok, todo_item} ->
        conn
        |> put_flash(:info, "Todo item created successfully.")
        |> redirect(to: ~p"/todos/#{todo_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user.id
    todo_item = Tasks.get_todo_item!(user_id, id)
    render(conn, :show, todo_item: todo_item)
  end

  def edit(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user.id
    todo_item = Tasks.get_todo_item!(user_id, id)
    changeset = Tasks.change_todo_item(todo_item)
    render(conn, :edit, todo_item: todo_item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "todo_item" => todo_item_params}) do
    user_id = conn.assigns.current_user.id
    todo_item = Tasks.get_todo_item!(user_id, id)

    case Tasks.update_todo_item(todo_item, todo_item_params) do
      {:ok, todo_item} ->
        conn
        |> put_flash(:info, "Todo item updated successfully.")
        |> redirect(to: ~p"/todos/#{todo_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, todo_item: todo_item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user.id
    todo_item = Tasks.get_todo_item!(user_id, id)
    {:ok, _todo_item} = Tasks.delete_todo_item(todo_item)

    conn
    |> put_flash(:info, "Todo item deleted successfully.")
    |> redirect(to: ~p"/todos")
  end
  
  def toggle_completed(conn, %{"id" => id, "completed" => _completed}) do
    user_id = conn.assigns.current_user.id
    todo_item = Tasks.get_todo_item!(user_id, id)
    
    # Toggle the completed status
    new_status = !todo_item.completed
    
    # Update the completed_at timestamp if being marked as completed
    attrs = if new_status do
      %{completed: true, completed_at: DateTime.truncate(DateTime.utc_now(), :second)}
    else
      %{completed: false, completed_at: nil}
    end
    
    {:ok, _todo_item} = Tasks.update_todo_item(todo_item, attrs)

    # Redirect back to the todos list
    redirect(conn, to: ~p"/todos")
  end
end
