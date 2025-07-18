defmodule ShophawkWeb.InvoiceCommentcomponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Dashboard
  alias Shophawk.Dashboard.InvoiceComments

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle></:subtitle>
      </.header>
      <div class="text-xl">
      <%= @document %>
      </div>

      <.simple_form
        for={@form}
        id="invoice-comment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:comment]} type="textarea" label={"Comment for Invoice #{@document}"} />
        <div class="hidden">
          <.input field={@form[:invoice]} type="text" value={@document} class="hidden" />
        </div>

        <:actions>
        <div class="flex justify-between items-center">
        <div>
          <.button phx-disable-with="Saving...">Checkin</.button>
        </div>
        </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def update(%{document: document} = assigns, socket) do
    params =
      %InvoiceComments{}
      |> InvoiceComments.changeset(%{document: document})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(params)}
  end

  def handle_event("save", %{"invoice_comments" => comment_params}, socket) do
    save_tool(socket, comment_params)
  end

  def handle_event("validate", %{"invoice_comments" => comment_params}, socket) do
    changeset =
      %InvoiceComments{}
      |> Dashboard.change_invoice_comment(comment_params)
      |> Map.put(:action, :validate)
    socket = assign_form(socket, changeset)
    {:noreply, socket}
  end



  defp save_tool(socket, comment_params) do
    case Dashboard.create_invoice_comment(comment_params) do
      {:ok, invoice} ->
        notify_parent({:saved, invoice})


        {:noreply,
         socket
         |> put_flash(:info, "Comment Added")
         |> push_patch(to: "/dashboard/accounting" )}  #NO PATCH ASSIGNED, WHAT DOES THE PATCH DO???

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

end
