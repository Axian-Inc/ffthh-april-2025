defmodule TodoWeb.TodoLive do
  # ========================================================================
  # This is the parent LiveView module for todo functionality.
  # 
  # ARCHITECTURE OVERVIEW:
  # - In Phoenix LiveView, a module hierarchy can be established where
  #   this module acts as a "base" or "parent" for specialized views
  # - Each specialized view (Index, Show, Edit, New) inherits from this module
  #   and extends or overrides its functionality as needed
  #
  # RELATIONSHIP TO ROUTER:
  # - The router.ex defines specific routes that map to specialized LiveViews
  #   like TodoLive.Index, TodoLive.Show, TodoLive.Edit, and TodoLive.New
  # - Each specialized view is a separate module with its own template and logic
  # ========================================================================
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.TodoItem

  # ========================================================================
  # MOUNT CALLBACK
  # This is called when the LiveView is first rendered
  # It's inherited by child LiveViews unless they override it
  #
  # Common initialization tasks are handled here:
  # - Getting the current user
  # - Loading initial data
  # - Setting up the initial socket state
  # ========================================================================
  @impl true
  def mount(_params, session, socket) do
    # Get the current user from the session
    current_user_id = get_user_id_from_session(session)

    if current_user_id do
      # Load all todos for the current user
      todos = Tasks.list_todos(current_user_id)

      # Initialize the socket with common state
      {:ok,
       assign(socket, todos: todos, current_user_id: current_user_id, page_title: "Todo List")}
    else
      # Redirect to login if not authenticated
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  # ========================================================================
  # HANDLE_PARAMS CALLBACK
  # Called when URL parameters change and after mount
  # 
  # This is a router for different actions within the LiveView:
  # - Delegates to apply_action based on the current live_action
  # - live_action comes from the router.ex configuration
  # ========================================================================
  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # ========================================================================
  # ACTION HANDLERS
  # These prepare the socket state based on the requested action
  # Each matches a different :live_action value from the router
  # ========================================================================

  # INDEX: Display the list of todos
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Todo List")
    |> assign(:todo_item, nil)
  end

  # NEW: Create a new todo
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Todo")
    |> assign(:todo_item, %TodoItem{})
  end

  # EDIT: Edit an existing todo
  defp apply_action(socket, :edit, %{"id" => id}) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    socket
    |> assign(:page_title, "Edit Todo")
    |> assign(:todo_item, todo_item)
  end

  # SHOW: Display a single todo
  defp apply_action(socket, :show, %{"id" => id}) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    socket
    |> assign(:page_title, todo_item.title)
    |> assign(:todo_item, todo_item)
  end

  # ========================================================================
  # EVENT HANDLERS
  # Process events triggered by user interactions
  #
  # These are shared across different view contexts, but can be
  # overridden by child LiveViews for specialized behavior
  # ========================================================================

  # DELETE: Remove a todo item
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)
    {:ok, _} = Tasks.delete_todo_item(todo_item)

    # Refresh todos list after deletion
    {:noreply, assign(socket, :todos, Tasks.list_todos(socket.assigns.current_user_id))}
  end

  # TOGGLE_COMPLETED: Change the completion status of a todo
  @impl true
  def handle_event("toggle_completed", %{"id" => id}, socket) do
    todo_item = Tasks.get_todo_item!(socket.assigns.current_user_id, id)

    # Toggle the completed status
    new_status = !todo_item.completed

    # Update the completed_at timestamp if being marked as completed
    attrs =
      if new_status do
        %{completed: true, completed_at: DateTime.truncate(DateTime.utc_now(), :second)}
      else
        %{completed: false, completed_at: nil}
      end

    {:ok, _todo_item} = Tasks.update_todo_item(todo_item, attrs)

    # Refresh todos list
    {:noreply, assign(socket, :todos, Tasks.list_todos(socket.assigns.current_user_id))}
  end

  # ========================================================================
  # HELPER FUNCTIONS
  # Common utilities used across all todo LiveView contexts
  # ========================================================================
  
  # Extract the user ID from the session token
  defp get_user_id_from_session(session) do
    with %{"user_token" => user_token} <- session,
         user = Todo.Accounts.get_user_by_session_token(user_token),
         do: user.id
  end
end
