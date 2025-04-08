defmodule TodoWeb.TodoLive.Show do
  use TodoWeb, :live_view

  alias Todo.Tasks

  @impl true
  def mount(_params, session, socket) do
    IO.puts("\n[Mount] 🚀 Show LiveView mounting")
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      # Subscribe to the user's todos topic for real-time updates
      if connected?(socket) do
        IO.puts("[Mount] 🔌 Show view socket connected, subscribing to todos:#{current_user_id}")
        Phoenix.PubSub.subscribe(Todo.PubSub, "todos:#{current_user_id}")
        IO.puts("        📡 Show view subscription active - will receive broadcasts")
      else
        IO.puts("[Mount] 🔄 Show view static render phase (JS not yet connected)")
      end

      IO.puts("[Mount] ✅ Show view initialized and ready for params")
      {:ok, assign(socket, current_user_id: current_user_id)}
    else
      IO.puts("[Mount] 🚫 User not authenticated, redirecting Show view to login")
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
    # [8] Log the received broadcast in Show LiveView
    IO.puts("\n[8] 📻 Show LiveView received broadcast: {:todo_completion_toggled}")
    IO.puts("    📦 Delta: %{id: #{delta.id}, completed: #{delta.completed}}")

    # Update only the completion status if we're viewing this todo
    if socket.assigns.todo_item && socket.assigns.todo_item.id == delta.id do
      IO.puts("[9] 🧩 Applying changes to Show LiveView state")

      updated_todo = %{
        socket.assigns.todo_item
        | completed: delta.completed,
          completed_at: delta.completed_at
      }

      IO.puts("    ✨ Triggering re-render of Show LiveView with updated state")
      {:noreply, assign(socket, todo_item: updated_todo)}
    else
      IO.puts("    ⏩ Ignoring update (different todo being viewed)")
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
    IO.puts("\n[Params] 🔍 Show view handling params with todo id: #{id}")
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    IO.puts("[Params] 📖 Loaded todo: '#{todo_item.title}', completed: #{todo_item.completed}")

    IO.puts("[Params] 🔄 Setting Show view state and triggering render")

    {:noreply,
     socket
     |> assign(:page_title, todo_item.title)
     |> assign(:todo_item, todo_item)}
  end

  @impl true
  def handle_event("toggle_completed", %{"id" => id}, socket) do
    # [1S] Log when the event is received in Show view
    IO.puts("\n[1S] 📩 Event received in SHOW VIEW: toggle_completed for todo ##{id}")

    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    # [2S] Log the current state
    IO.puts(
      "[2S] 🔄 Toggling todo: '#{todo_item.title}' from #{todo_item.completed} to #{!todo_item.completed}"
    )

    # Toggle the completed status
    new_status = !todo_item.completed

    # Create completed_at timestamp if being marked as completed
    completed_at = if new_status, do: DateTime.truncate(DateTime.utc_now(), :second), else: nil
    attrs = %{completed: new_status, completed_at: completed_at}

    # [3S] Log the database update
    IO.puts("[3S] 💾 Updating database from SHOW view...")
    {:ok, updated_todo} = Tasks.update_todo_item(todo_item, attrs)
    IO.puts("    ✅ Database updated successfully")

    # Create a minimal delta with only changed fields
    delta = %{
      id: todo_item.id,
      completed: new_status,
      completed_at: completed_at
    }

    # [4S] Log the broadcast
    IO.puts("[4S] 📡 Broadcasting from SHOW VIEW to todos:#{socket.assigns.current_user_id}")

    Phoenix.PubSub.broadcast(
      Todo.PubSub,
      "todos:#{socket.assigns.current_user_id}",
      {:todo_completion_toggled, delta}
    )

    IO.puts("    📣 Message sent: {:todo_completion_toggled, delta}")

    # [5S] Log the local state update
    IO.puts("[5S] 🔄 Updating local state for Show view socket")
    IO.puts("    ✅ Local Show view state updated, initiating re-render")
    {:noreply, assign(socket, :todo_item, updated_todo)}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end
