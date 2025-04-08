defmodule TodoWeb.TodoLive.New do
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  @impl true
  def mount(_params, session, socket) do
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      changeset = Tasks.change_todo_item(%TodoItem{})

      {:ok,
       socket
       |> assign(:current_user_id, current_user_id)
       |> assign(:todo_item, %TodoItem{})
       |> assign(:changeset, to_form(changeset))
       |> assign(:page_title, "New Todo")}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
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
    # Add user_id to params
    todo_params = Map.put(todo_params, "user_id", socket.assigns.current_user_id)

    case Tasks.create_todo_item(todo_params) do
      {:ok, todo} ->
        # Only send the necessary fields for a new todo creation
        # This avoids sending internal fields and empty values
        todo_data = %{
          id: todo.id,
          title: todo.title,
          description: todo.description,
          due_date: todo.due_date,
          completed: todo.completed,
          created_at: todo.created_at,
          priority: todo.priority
        }

        # Broadcast just the creation event with minimal data
        Phoenix.PubSub.broadcast(
          Todo.PubSub,
          "todos:#{socket.assigns.current_user_id}",
          {:todo_created, todo_data}
        )

        {:noreply,
         socket
         |> put_flash(:info, "Todo created successfully")
         |> redirect(to: ~p"/todos")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: to_form(changeset))}
    end
  end

  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end
