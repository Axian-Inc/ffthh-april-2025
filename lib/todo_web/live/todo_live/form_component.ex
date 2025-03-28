defmodule TodoWeb.TodoLive.FormComponent do
  use TodoWeb, :live_component

  alias Todo.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="todo-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" required />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:due_date]} type="date" label="Due date" />
        <.input field={@form[:completed]} type="checkbox" label="Completed" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Todo</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{todo_item: todo_item} = assigns, socket) do
    changeset = Tasks.change_todo_item(todo_item)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"todo_item" => todo_item_params}, socket) do
    changeset =
      socket.assigns.todo_item
      |> Tasks.change_todo_item(todo_item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"todo_item" => todo_item_params}, socket) do
    save_todo_item(socket, socket.assigns.action, todo_item_params)
  end

  defp save_todo_item(socket, :edit, todo_item_params) do
    case Tasks.update_todo_item(socket.assigns.todo_item, todo_item_params) do
      {:ok, _todo_item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Todo updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_todo_item(socket, :new, todo_item_params) do
    # Add the current user's ID to the todo item params
    todo_item_params = Map.put(todo_item_params, "user_id", socket.assigns.current_user_id)

    case Tasks.create_todo_item(todo_item_params) do
      {:ok, _todo_item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Todo created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
