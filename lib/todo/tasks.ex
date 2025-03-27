defmodule Todo.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias Todo.Repo

  alias Todo.Tasks.TodoItem

  @doc """
  Returns the list of todos for a specific user.

  ## Examples

      iex> list_todos(user_id)
      [%TodoItem{}, ...]

  """
  def list_todos(user_id) do
    from(t in TodoItem, where: t.user_id == ^user_id)
    |> Repo.all()
  end
  
  @doc """
  Returns the list of all todos - use with caution.
  """
  def list_todos do
    Repo.all(TodoItem)
  end

  @doc """
  Gets a single todo_item for a specific user.

  Raises `Ecto.NoResultsError` if the Todo item does not exist or doesn't belong to the user.

  ## Examples

      iex> get_todo_item!(user_id, 123)
      %TodoItem{}

      iex> get_todo_item!(user_id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_todo_item!(user_id, id) do
    from(t in TodoItem, where: t.id == ^id and t.user_id == ^user_id)
    |> Repo.one!()
  end
  
  @doc """
  Gets a single todo_item without user validation.
  Use with caution.
  """
  def get_todo_item!(id), do: Repo.get!(TodoItem, id)

  @doc """
  Creates a todo_item.

  ## Examples

      iex> create_todo_item(%{field: value})
      {:ok, %TodoItem{}}

      iex> create_todo_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo_item(attrs \\ %{}) do
    %TodoItem{}
    |> TodoItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo_item.

  ## Examples

      iex> update_todo_item(todo_item, %{field: new_value})
      {:ok, %TodoItem{}}

      iex> update_todo_item(todo_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo_item(%TodoItem{} = todo_item, attrs) do
    todo_item
    |> TodoItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo_item.

  ## Examples

      iex> delete_todo_item(todo_item)
      {:ok, %TodoItem{}}

      iex> delete_todo_item(todo_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo_item(%TodoItem{} = todo_item) do
    Repo.delete(todo_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo_item changes.

  ## Examples

      iex> change_todo_item(todo_item)
      %Ecto.Changeset{data: %TodoItem{}}

  """
  def change_todo_item(%TodoItem{} = todo_item, attrs \\ %{}) do
    TodoItem.changeset(todo_item, attrs)
  end
end
