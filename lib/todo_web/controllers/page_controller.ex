defmodule TodoWeb.PageController do
  use TodoWeb, :controller

  def home(conn, _params) do
    # Redirect to todos if user is logged in
    if conn.assigns[:current_user] do
      # The path is the same, but now it's a LiveView
      redirect(conn, to: ~p"/todos")
    else
      # The home page is often custom made,
      # so skip the default app layout.
      render(conn, :home, layout: false)
    end
  end
end
