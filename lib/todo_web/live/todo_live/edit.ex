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
        # Broadcast the update to all clients
        Phoenix.PubSub.broadcast(
          Todo.PubSub,
          "todos:#{socket.assigns.current_user_id}",
          {:todo_updated, updated_todo}
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