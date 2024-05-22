defmodule ShophawkWeb.TimeoffLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Shopinfo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage timeoff records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="timeoff-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:employee]} type="text" label="Employee" />
        <.input field={@form[:startdate]} type="datetime-local" label="Startdate" />
        <.input field={@form[:enddate]} type="datetime-local" label="Enddate" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Timeoff</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{timeoff: timeoff} = assigns, socket) do
    changeset = Shopinfo.change_timeoff(timeoff)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"timeoff" => timeoff_params}, socket) do
    changeset =
      socket.assigns.timeoff
      |> Shopinfo.change_timeoff(timeoff_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"timeoff" => timeoff_params}, socket) do
    save_timeoff(socket, socket.assigns.action, timeoff_params)
  end

  defp save_timeoff(socket, :edit, timeoff_params) do
    case Shopinfo.update_timeoff(socket.assigns.timeoff, timeoff_params) do
      {:ok, timeoff} ->
        notify_parent({:saved, timeoff})

        {:noreply,
         socket
         |> put_flash(:info, "Timeoff updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_timeoff(socket, :new, timeoff_params) do
    case Shopinfo.create_timeoff(timeoff_params) do
      {:ok, timeoff} ->
        notify_parent({:saved, timeoff})

        {:noreply,
         socket
         |> put_flash(:info, "Timeoff created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
