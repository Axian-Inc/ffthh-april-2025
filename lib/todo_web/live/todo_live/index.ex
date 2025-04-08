defmodule TodoWeb.TodoLive.Index do
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  @impl true
  def mount(params, session, socket) do
    IO.puts("\n[Mount] 🚀 Index LiveView mounting")
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      # Subscribe to the user's todos topic for real-time updates
      if connected?(socket) do
        IO.puts("[Mount] 🔌 Socket connected, subscribing to todos:#{current_user_id}")
        Phoenix.PubSub.subscribe(Todo.PubSub, "todos:#{current_user_id}")
        IO.puts("        📡 Subscription active - this view will receive broadcasts")
      else
        IO.puts("[Mount] 🔄 Static render phase (JS not yet connected)")
      end

      # Get priority filter from params, only accept valid values
      priority_filter = 
        if params["priority"] in TodoItem.priorities() do
          params["priority"]
        else
          nil
        end
      IO.puts("[Mount] 🔍 Priority filter: #{inspect(priority_filter)}")
      
      IO.puts("[Mount] 📥 Loading initial todos from database")
      todos = Tasks.list_todos(current_user_id, priority_filter)
      IO.puts("        ✅ Found #{length(todos)} todos, initializing LiveView state")

      {:ok, assign(socket, 
        todos: todos, 
        current_user_id: current_user_id,
        priority_filter: priority_filter,
        priorities: TodoItem.priorities()
      )}
    else
      IO.puts("[Mount] 🚫 User not authenticated, redirecting to login")
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
    # [6] Log the received broadcast in Index LiveView
    IO.puts("\n[6] 📻 Index LiveView received broadcast: {:todo_completion_toggled}")
    IO.puts("    📦 Delta: %{id: #{delta.id}, completed: #{delta.completed}}")

    # Update only the completion status of the todo
    IO.puts("[7] 🧩 Applying changes to Index LiveView state")

    updated_todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == delta.id do
          %{todo | completed: delta.completed, completed_at: delta.completed_at}
        else
          todo
        end
      end)

    IO.puts("    ✨ Triggering re-render of Index LiveView with updated state")
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
    # Get priority filter from params, only accept valid values
    priority_filter = 
      if params["priority"] in TodoItem.priorities() do
        params["priority"]
      else
        nil
      end
    
    # Reload todos with filter if priority param changed
    socket = if Map.get(socket.assigns, :priority_filter) != priority_filter do
      todos = Tasks.list_todos(socket.assigns.current_user_id, priority_filter)
      assign(socket, todos: todos, priority_filter: priority_filter)
    else
      socket
    end
    
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
    # [1] Log when the event is received
    IO.puts("\n[1] 📩 Event received: toggle_completed for todo ##{id}")

    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    # [2] Log the current state
    IO.puts(
      "[2] 🔄 Toggling todo: '#{todo_item.title}' from #{todo_item.completed} to #{!todo_item.completed}"
    )

    # Toggle the completed status
    new_status = !todo_item.completed

    # Create completed_at timestamp if being marked as completed
    completed_at = if new_status, do: DateTime.truncate(DateTime.utc_now(), :second), else: nil
    attrs = %{completed: new_status, completed_at: completed_at}

    # [3] Log the database update
    IO.puts("[3] 💾 Updating database...")
    {:ok, updated_todo} = Tasks.update_todo_item(todo_item, attrs)
    IO.puts("    ✅ Database updated successfully")

    # Create a minimal delta with only changed fields
    delta = %{
      id: todo_item.id,
      completed: new_status,
      completed_at: completed_at
    }

    # [4] Log the broadcast
    IO.puts("[4] 📡 Broadcasting to todos:#{socket.assigns.current_user_id}")

    Phoenix.PubSub.broadcast(
      Todo.PubSub,
      "todos:#{socket.assigns.current_user_id}",
      {:todo_completion_toggled, delta}
    )

    IO.puts("    📣 Message sent: {:todo_completion_toggled, delta}")

    # [5] Log the local state update
    IO.puts("[5] 🔄 Updating local state for current socket")
    # Update the todo in-memory instead of re-fetching from database
    updated_todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == todo_item.id, do: updated_todo, else: todo
      end)

    IO.puts("    ✅ Local state updated, initiating re-render")
    {:noreply, assign(socket, :todos, updated_todos)}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
  
  # Helper function to get the color classes for a priority badge
  defp get_priority_colors(priority) do
    case priority do
      "high" -> "bg-red-100 text-red-800"
      "normal" -> "bg-blue-100 text-blue-800"
      "low" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
  
  # Helper function to get the ring color for the selected priority filter
  defp priority_ring_color(priority) do
    case priority do
      "high" -> "ring-red-500"
      "normal" -> "ring-blue-500"
      "low" -> "ring-gray-500"
      _ -> "ring-gray-500"
    end
  end
end
