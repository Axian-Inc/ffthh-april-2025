defmodule Todo.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todo.Tasks` context.
  """

  @doc """
  Generate a todo_item.
  """
  def todo_item_fixture(attrs \\ %{}) do
    {:ok, todo_item} =
      attrs
      |> Enum.into(%{
        completed: true,
        completed_at: ~U[2025-03-26 20:18:00Z],
        created_at: ~U[2025-03-26 20:18:00Z],
        description: "some description",
        due_date: ~D[2025-03-26],
        title: "some title"
      })
      |> Todo.Tasks.create_todo_item()

    todo_item
  end
end
