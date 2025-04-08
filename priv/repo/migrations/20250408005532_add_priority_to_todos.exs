defmodule Todo.Repo.Migrations.AddPriorityToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :priority, :string, default: "normal", null: false
    end

    create index(:todos, [:priority])
  end
end
