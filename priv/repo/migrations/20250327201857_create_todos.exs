defmodule Todo.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string
      add :description, :text
      add :due_date, :date
      add :completed, :boolean, default: false, null: false
      add :created_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:todos, [:user_id])
  end
end
