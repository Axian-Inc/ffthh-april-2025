defmodule TodoWeb.TodoLive.Edit do
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  @impl true
  def mount(_params, session, socket) do
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      {:ok, assign(socket, current_user_id: current_user_id)}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    changeset = Tasks.change_todo_item(todo_item)

    {:noreply,
     socket
     |> assign(:page_title, "Edit Todo")
     |> assign(:todo_item, todo_item)
     |> assign(:changeset, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"todo_item" => todo_params}, socket) do
    changeset =
      socket.assigns.todo_item
      |> Tasks.change_todo_item(todo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"todo_item" => todo_params}, socket) do
    case Tasks.update_todo_item(socket.assigns.todo_item, todo_params) do
      {:ok, updated_todo} ->
        # Extract only the changed fields by comparing with original
        original = socket.assigns.todo_item
        
        # Create a delta map with only the changed attributes
        delta = %{id: updated_todo.id}
        
        # Only include fields that have changed
        delta = if original.title != updated_todo.title,
          do: Map.put(delta, :title, updated_todo.title), else: delta
          
        delta = if original.description != updated_todo.description,
          do: Map.put(delta, :description, updated_todo.description), else: delta
          
        delta = if original.due_date != updated_todo.due_date,
          do: Map.put(delta, :due_date, updated_todo.due_date), else: delta
          
        delta = if original.completed != updated_todo.completed,
          do: Map.put(delta, :completed, updated_todo.completed), else: delta
          
        delta = if original.completed_at != updated_todo.completed_at,
          do: Map.put(delta, :completed_at, updated_todo.completed_at), else: delta
        
        # Broadcast only the delta of changed fields
        Phoenix.PubSub.broadcast(
          Todo.PubSub,
          "todos:#{socket.assigns.current_user_id}",
          {:todo_fields_updated, delta}
        )
        
        {:noreply,
         socket
         |> put_flash(:info, "Todo updated successfully")
         |> redirect(to: ~p"/todos")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, to_form(changeset))}
    end
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end