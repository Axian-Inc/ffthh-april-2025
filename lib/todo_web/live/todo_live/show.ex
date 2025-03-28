defmodule TodoWeb.TodoLive.Show do
  use TodoWeb, :live_view

  alias Todo.Tasks

  @impl true
  def mount(_params, session, socket) do
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      # Subscribe to the user's todos topic for real-time updates
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Todo.PubSub, "todos:#{current_user_id}")
      end

      {:ok, assign(socket, current_user_id: current_user_id)}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_info({:todo_updated, todo_item}, socket) do
    # Legacy handler for full todo updates
    if socket.assigns.todo_item && socket.assigns.todo_item.id == todo_item.id do
      {:noreply, assign(socket, todo_item: todo_item)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:todo_completion_toggled, delta}, socket) do
    # Update only the completion status if we're viewing this todo
    if socket.assigns.todo_item && socket.assigns.todo_item.id == delta.id do
      updated_todo = %{
        socket.assigns.todo_item
        | completed: delta.completed,
          completed_at: delta.completed_at
      }

      {:noreply, assign(socket, todo_item: updated_todo)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:todo_fields_updated, delta}, socket) do
    # Apply only the changed fields if we're viewing this todo
    if socket.assigns.todo_item && socket.assigns.todo_item.id == delta.id do
      # Apply each field in the delta to the todo
      updated_todo =
        Enum.reduce(Map.drop(delta, [:id]), socket.assigns.todo_item, fn {field, value}, acc ->
          Map.put(acc, field, value)
        end)

      {:noreply, assign(socket, todo_item: updated_todo)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:todo_deleted, todo_id}, socket) do
    # If we're viewing the todo that was deleted, redirect to the index page
    if socket.assigns.todo_item && socket.assigns.todo_item.id == todo_id do
      {:noreply, push_navigate(socket, to: ~p"/todos")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    {:noreply,
     socket
     |> assign(:page_title, todo_item.title)
     |> assign(:todo_item, todo_item)}
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

    {:noreply, assign(socket, :todo_item, updated_todo)}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end
