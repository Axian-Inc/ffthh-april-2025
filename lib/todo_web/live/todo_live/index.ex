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
  def handle_info({:todo_updated, _todo_item}, socket) do
    # Refresh todos list when a todo is updated
    todos = Tasks.list_todos(socket.assigns.current_user_id)
    {:noreply, assign(socket, todos: todos)}
  end
  
  @impl true
  def handle_info({:todo_created, _todo_item}, socket) do
    # Refresh todos list when a new todo is created
    todos = Tasks.list_todos(socket.assigns.current_user_id)
    {:noreply, assign(socket, todos: todos)}
  end
  
  @impl true
  def handle_info({:todo_deleted, _todo_id}, socket) do
    # Refresh todos list when a todo is deleted
    todos = Tasks.list_todos(socket.assigns.current_user_id)
    {:noreply, assign(socket, todos: todos)}
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
    
    # Broadcast the deletion to all clients
    Phoenix.PubSub.broadcast(
      Todo.PubSub,
      "todos:#{socket.assigns.current_user_id}",
      {:todo_deleted, id}
    )

    {:noreply, assign(socket, :todos, Tasks.list_todos(socket.assigns.current_user_id))}
  end

  @impl true
  def handle_event("toggle_completed", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    
    # Toggle the completed status
    new_status = !todo_item.completed
    
    # Update the completed_at timestamp if being marked as completed
    attrs = if new_status do
      %{completed: true, completed_at: DateTime.truncate(DateTime.utc_now(), :second)}
    else
      %{completed: false, completed_at: nil}
    end
    
    {:ok, updated_todo} = Tasks.update_todo_item(todo_item, attrs)
    
    # Broadcast the update to all clients
    Phoenix.PubSub.broadcast(
      Todo.PubSub,
      "todos:#{socket.assigns.current_user_id}",
      {:todo_updated, updated_todo}
    )

    # Refresh todos list
    {:noreply, assign(socket, :todos, Tasks.list_todos(socket.assigns.current_user_id))}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end