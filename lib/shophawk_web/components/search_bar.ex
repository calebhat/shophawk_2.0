# lib/my_app_web/components/search_bar.ex
defmodule ShophawkWeb.Components.SearchBar do
  use Phoenix.Component
  #import Phoenix.HTML.Form
  import ShophawkWeb.CoreComponents, only: [input: 1]

  def search_bar(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "search-bar" end)
      |> assign_new(:placeholder, fn -> "Search..." end)
      |> assign_new(:change_event, fn -> "search_change" end)
      |> assign_new(:submit_event, fn -> "search_submit" end)

    ~H"""
    <form id={@id <> "-form"} phx-change={@change_event} phx-submit={@submit_event}>
      <.input
        type="text"
        name="query"
        value={Map.get(@form_params, :query, "")}
        placeholder={@placeholder}
        phx-debounce="300"
      />
    </form>
    """
  end
end
