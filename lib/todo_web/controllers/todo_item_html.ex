defmodule TodoWeb.TodoItemHTML do
  use TodoWeb, :html

  embed_templates "todo_item_html/*"

  @doc """
  Renders a todo_item form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def todo_item_form(assigns)
end
