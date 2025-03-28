defmodule TodoWeb.TodoLive.Index do
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  @impl true
  def mount(_params, session, socket) do
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      # Subscribe to the user's todos topic for real-time updates
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Todo.PubSub, "todos:#{current_user_id}")
      end

      todos = Tasks.list_todos(current_user_id)
      {:ok, assign(socket, todos: todos, current_user_id: current_user_id)}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_info({:todo_updated, todo_item}, socket) do
    # Legacy handler for full todo updates - update the specific todo
    updated_todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == todo_item.id, do: todo_item, else: todo
      end)

    {:noreply, assign(socket, todos: updated_todos)}
  end

  @impl true
  def handle_info({:todo_completion_toggled, delta}, socket) do
    # Update only the completion status of the todo
    updated_todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == delta.id do
          %{todo | completed: delta.completed, completed_at: delta.completed_at}
        else
          todo
        end
      end)

    {:noreply, assign(socket, todos: updated_todos)}
  end

  @impl true
  def handle_info({:todo_fields_updated, delta}, socket) do
    # Apply only the changed fields to the specific todo
    updated_todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == delta.id do
          # Apply each field in the delta to the todo
          Enum.reduce(Map.drop(delta, [:id]), todo, fn {field, value}, acc ->
            Map.put(acc, field, value)
          end)
        else
          todo
        end
      end)

    {:noreply, assign(socket, todos: updated_todos)}
  end

  @impl true
  def handle_info({:todo_created, todo_data}, socket) do
    # Convert map to a proper TodoItem struct
    new_todo = struct(TodoItem, Map.to_list(todo_data))

    # Add the new todo to the list without fetching from the database
    updated_todos = [new_todo | socket.assigns.todos]

    {:noreply, assign(socket, todos: updated_todos)}
  end

  @impl true
  def handle_info({:todo_deleted, todo_id}, socket) do
    # Filter out the deleted todo from the list
    updated_todos =
      Enum.reject(socket.assigns.todos, fn todo ->
        todo.id == todo_id
      end)

    {:noreply, assign(socket, todos: updated_todos)}
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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    {:ok, _} = Tasks.delete_todo_item(todo_item)

    # Broadcast the deletion to all clients with minimal data
    Phoenix.PubSub.broadcast(
      Todo.PubSub,
      "todos:#{socket.assigns.current_user_id}",
      {:todo_deleted, id}
    )

    # Update todos in-memory by filtering out the deleted todo
    updated_todos = Enum.reject(socket.assigns.todos, fn todo -> todo.id == todo_item.id end)

    {:noreply, assign(socket, :todos, updated_todos)}
  end

  @impl true
  def handle_event("toggle_completed", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    # Toggle the completed status
    new_status = !todo_item.completed

    # Create completed_at timestamp if being marked as completed
    completed_at = if new_status, do: DateTime.truncate(DateTime.utc_now(), :second), else: nil
    attrs = %{completed: new_status, completed_at: completed_at}

    {:ok, updated_todo} = Tasks.update_todo_item(todo_item, attrs)

    # Create a minimal delta with only changed fields
    delta = %{
      id: todo_item.id,
      completed: new_status,
      completed_at: completed_at
    }

    # Broadcast specific event type with minimal data
    Phoenix.PubSub.broadcast(
      Todo.PubSub,
      "todos:#{socket.assigns.current_user_id}",
      {:todo_completion_toggled, delta}
    )

    # Update the todo in-memory instead of re-fetching from database
    updated_todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == todo_item.id, do: updated_todo, else: todo
      end)

    {:noreply, assign(socket, :todos, updated_todos)}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end
