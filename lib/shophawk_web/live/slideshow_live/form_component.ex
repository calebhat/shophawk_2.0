defmodule ShophawkWeb.SlideshowLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Shopinfo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage slideshow records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="slideshow-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
      <div class="grid grid-cols-2">
        <div class="bg-cyan-700 rounded-lg m-4">
          <div class="mt-4 text-2xl flex justify-center border-b-4 border-black">Current Week</div>
          <div class="grid grid-cols-3 gap-4 content-center flex justify-around p-2 m-2 text-xl">
            <div class="flex justify-center grid content-center">Monday</div>
            <.input field={@form[:mondayo1]} type="time" label="" />
            <.input field={@form[:mondayc1]} type="time" label="" />
            <div class="flex justify-center grid content-center">Tuesday</div>
            <.input field={@form[:tuesdayo1]} type="time" label="" />
            <.input field={@form[:tuesdayc1]} type="time" label="" />
            <div class="flex justify-center grid content-center">Wednesday</div>
            <.input field={@form[:wednesdayo1]} type="time" label="" />
            <.input field={@form[:wednesdayc1]} type="time" label="" />
            <div class="flex justify-center grid content-center">Thursday</div>
            <.input field={@form[:thursdayo1]} type="time" label="" />
            <.input field={@form[:thursdayc1]} type="time" label="" />
            <div class="flex justify-center grid content-center">Friday</div>
            <.input field={@form[:fridayo1]} type="time" label="" />
            <.input field={@form[:fridayc1]} type="time" label="" />
            <div class="flex justify-center grid content-center">Saturday</div>
            <.input field={@form[:saturdayo1]} type="time" label="" />
            <.input field={@form[:saturdayc1]} type="time" label="" />
          </div>
          <div class="grid grid-cols-2 content-center text-xl mb-4">
            <div class="flex justify-center">Show Saturday:</div>
            <.input field={@form[:showsaturday1]} type="checkbox" label="" />
          </div>
        </div>
        <div class="bg-cyan-700 rounded-lg m-4">
          <div class="mt-4 text-2xl flex justify-center border-b-4 border-black">Next Week</div>
          <div class="grid grid-cols-3 gap-4 content-center flex justify-around p-2 m-2 text-xl">
            <div class="cflex justify-center grid content-center">Monday</div>
            <.input field={@form[:mondayo2]} type="time" label="" />
            <.input field={@form[:mondayc2]} type="time" label="" />
            <div class="flex justify-center grid content-center">Tuesday</div>
            <.input field={@form[:tuesdayo2]} type="time" label="" />
            <.input field={@form[:tuesdayc2]} type="time" label="" />
            <div class="flex justify-center grid content-center">Wednesday</div>
            <.input field={@form[:wednesdayo2]} type="time" label="" />
            <.input field={@form[:wednesdayc2]} type="time" label="" />
            <div class="flex justify-center grid content-center">Thursday</div>
            <.input field={@form[:thursdayo2]} type="time" label="" />
            <.input field={@form[:thursdayc2]} type="time" label="" />
            <div class="flex justify-center grid content-center">Friday</div>
            <.input field={@form[:fridayo2]} type="time" label="" />
            <.input field={@form[:fridayc2]} type="time" label="" />
            <div class="flex justify-center grid content-center">Saturday</div>
            <.input field={@form[:saturdayo2]} type="time" label="" />
            <.input field={@form[:saturdayc2]} type="time" label="" />
          </div>
          <div class="grid grid-cols-2 content-center text-xl mb-4">
            <div class="flex justify-center">Show Saturday:</div>
            <.input field={@form[:showsaturday2]} type="checkbox" label=""/>
          </div>
        </div>
      </div>
      <!-- <.input field={@form[:workhours]} type="text" label="Workhours" /> -->
      <.input field={@form[:announcement1]} type="textarea" label="Announcement1" />
      <.input field={@form[:announcement2]} type="textarea" label="Annountment2" />
      <.input field={@form[:announcement3]} type="textarea" label="Announcemnet3" />
      <.input field={@form[:quote]} type="text" label="Quote" />
      <.input field={@form[:photo]} type="text" label="Photo" />

      <:actions>
        <.button phx-disable-with="Saving...">Save Slideshow</.button>
      </:actions>
    </.simple_form>
  </div>
  """
end

  @impl true
  def update(%{slideshow: slideshow} = assigns, socket) do
    map_keys = [:mondayo1, :mondayc1, :tuesdayo1, :tuesdayc1, :wednesdayo1, :wednesdayc1, :thursdayo1, :thursdayc1, :fridayo1, :fridayc1, :saturdayo1, :saturdayc1, :mondayo2, :mondayc2, :tuesdayo2, :tuesdayc2, :wednesdayo2, :wednesdayc2, :thursdayo2, :thursdayc2, :fridayo2, :fridayc2, :saturdayo2, :saturdayc2, :showsaturday1, :showsaturday2]
    slideshow =
      String.split(slideshow.workhours, ",")
      |> Enum.map(fn x ->
        case x do
          "true" -> true
          "false" -> false
          _ -> x
        end
      end)
      |> Enum.zip(map_keys)
      |> Enum.reduce(slideshow, fn {value, key}, acc ->
        Map.put(acc, key, value)
      end)
    changeset = Shopinfo.change_slideshow(slideshow)
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"slideshow" => slideshow_params}, socket) do
    slideshow_params = combine_hours(slideshow_params)
    changeset =
      socket.assigns.slideshow
      |> Shopinfo.change_slideshow(slideshow_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"slideshow" => slideshow_params}, socket) do
    save_slideshow(socket, socket.assigns.action, slideshow_params)
  end

  defp save_slideshow(socket, :edit, slideshow_params) do
    slideshow_params = combine_hours(slideshow_params)
    case Shopinfo.update_slideshow(socket.assigns.slideshow, slideshow_params) do
      {:ok, slideshow} ->
        notify_parent({:saved, slideshow})

        {:noreply,
         socket
         |> put_flash(:info, "Slideshow updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_slideshow(socket, :new, slideshow_params) do
    case Shopinfo.create_slideshow(slideshow_params) do
      {:ok, slideshow} ->
        notify_parent({:saved, slideshow})

        {:noreply,
         socket
         |> put_flash(:info, "Slideshow created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset)
    socket = assign(socket, :form, form)
    IO.inspect(socket.assigns)
    socket
  end

  defp combine_hours(slideshow_params) do
    workhours = "#{slideshow_params["mondayo1"]},#{slideshow_params["mondayc1"]},#{slideshow_params["tuesdayo1"]},#{slideshow_params["tuesdayc1"]},#{slideshow_params["wednesdayo1"]},#{slideshow_params["wednesdayc1"]},#{slideshow_params["thursdayo1"]},#{slideshow_params["thursdayc1"]},#{slideshow_params["fridayo1"]},#{slideshow_params["fridayc1"]},#{slideshow_params["saturdayo1"]},#{slideshow_params["saturdayc1"]},#{slideshow_params["mondayo2"]},#{slideshow_params["mondayc2"]},#{slideshow_params["tuesdayo2"]},#{slideshow_params["tuesdayc2"]},#{slideshow_params["wednesdayo2"]},#{slideshow_params["wednesdayc2"]},#{slideshow_params["thursdayo2"]},#{slideshow_params["thursdayc2"]},#{slideshow_params["fridayo2"]},#{slideshow_params["fridayc2"]},#{slideshow_params["saturdayo2"]},#{slideshow_params["saturdayc2"]},#{slideshow_params["showsaturday1"]},#{slideshow_params["showsaturday2"]}"
    Map.put(slideshow_params, "workhours", workhours)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
