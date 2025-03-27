defmodule TodoWeb.TodoLive.Show do
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
      
      {:ok, assign(socket, current_user_id: current_user_id)}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end
  
  @impl true
  def handle_info({:todo_updated, todo_item}, socket) do
    # If we're viewing this todo, update it
    if socket.assigns.todo_item && socket.assigns.todo_item.id == todo_item.id do
      {:noreply, assign(socket, todo_item: todo_item)}
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

    {:noreply, assign(socket, :todo_item, updated_todo)}
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end