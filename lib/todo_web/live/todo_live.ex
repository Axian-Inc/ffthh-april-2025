defmodule TodoWeb.TodoLive do
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  @impl true
  def mount(_params, session, socket) do
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      todos = Tasks.list_todos(current_user_id)

      {:ok,
       assign(socket, todos: todos, current_user_id: current_user_id, page_title: "Todo List")}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Todo List")
    |> assign(:todo_item, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Todo")
    |> assign(:todo_item, %TodoItem{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    socket
    |> assign(:page_title, "Edit Todo")
    |> assign(:todo_item, todo_item)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    socket
    |> assign(:page_title, todo_item.title)
    |> assign(:todo_item, todo_item)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    {:ok, _} = Tasks.delete_todo_item(todo_item)

    {:noreply, assign(socket, :todos, Tasks.list_todos(socket.assigns.current_user_id))}
  end

  @impl true
  def handle_event("toggle_completed", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    # Toggle the completed status
    new_status = !todo_item.completed

    # Update the completed_at timestamp if being marked as completed
    attrs =
      if new_status do
        %{completed: true, completed_at: DateTime.truncate(DateTime.utc_now(), :second)}
      else
        %{completed: false, completed_at: nil}
      end

    {:ok, _todo_item} = Tasks.update_todo_item(todo_item, attrs)

    # Refresh todos list
    {:noreply, assign(socket, :todos, Tasks.list_todos(socket.assigns.current_user_id))}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end
