defmodule Todo.Tasks.TodoItem do
  use Ecto.Schema
  import Ecto.Changeset

  @priorities ["low", "normal", "high"]
  def priorities, do: @priorities

  schema "todos" do
    field :description, :string
    field :title, :string
    field :due_date, :date
    field :completed, :boolean, default: false
    field :created_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now(), :second)
    field :completed_at, :utc_datetime
    field :priority, :string, default: "normal"

    belongs_to :user, Todo.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo_item, attrs) do
    todo_item
    |> cast(attrs, [
      :title,
      :description,
      :due_date,
      :completed,
      :created_at,
      :completed_at,
      :user_id,
      :priority
    ])
    |> validate_required([:title, :user_id])
    |> validate_inclusion(:priority, @priorities)
    |> foreign_key_constraint(:user_id)
    |> maybe_set_completed_time()
  end

  defp maybe_set_completed_time(changeset) do
    case get_change(changeset, :completed) do
      true -> put_change(changeset, :completed_at, DateTime.truncate(DateTime.utc_now(), :second))
      _ -> changeset
    end
  end
end
