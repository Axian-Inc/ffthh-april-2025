defmodule Todo.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todo.Tasks` context.
  """

  import Todo.AccountsFixtures

  @doc """
  Generate a todo_item.
  """
  def todo_item_fixture(attrs \\ %{}) do
    # Create a user if not provided in attrs
    user = attrs[:user] || user_fixture()
    
    {:ok, todo_item} =
      attrs
      |> Enum.into(%{
        completed: true,
        completed_at: ~U[2025-03-26 20:18:00Z],
        created_at: ~U[2025-03-26 20:18:00Z],
        description: "some description",
        due_date: ~D[2025-03-26],
        title: "some title",
        user_id: user.id
      })
      |> Todo.Tasks.create_todo_item()

    todo_item
  end
end
