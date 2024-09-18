defmodule ShophawkWeb.SlideshowLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Shopinfo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
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
          <div class="grid grid-cols-4 gap-4 content-center justify-around p-2 m-2 text-xl">
            <div></div>
            <div></div>
            <div></div>
            <div class="text-center">Closed</div>
            <div class="grid content-center justify-center">Monday</div>
            <.input field={@form[:mondayo1]} type="time" label="" />
            <.input field={@form[:mondayc1]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:monday1closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Tuesday</div>
            <.input field={@form[:tuesdayo1]} type="time" label="" />
            <.input field={@form[:tuesdayc1]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:tuesday1closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Wednesday</div>
            <.input field={@form[:wednesdayo1]} type="time" label="" />
            <.input field={@form[:wednesdayc1]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:wednesday1closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Thursday</div>
            <.input field={@form[:thursdayo1]} type="time" label="" />
            <.input field={@form[:thursdayc1]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:thursday1closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Friday</div>
            <.input field={@form[:fridayo1]} type="time" label="" />
            <.input field={@form[:fridayc1]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:friday1closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Saturday</div>
            <.input field={@form[:saturdayo1]} type="time" label="" />
            <.input field={@form[:saturdayc1]} type="time" label="" />
            <div></div>
            <div class="grid content-center justify-center col-span-2">Show Saturday:</div>
            <div class=" m-auto">
              <.input field={@form[:showsaturday1]} type="checkbox" label=""/>
            </div>
            <div></div>
            <div></div>
          </div>
        </div>
        <div class="bg-cyan-700 rounded-lg m-4">
          <div class="mt-4 text-2xl flex justify-center border-b-4 border-black">Next Week</div>
          <div class="grid grid-cols-4 gap-4 content-center justify-around p-2 m-2 text-xl">
            <div></div>
            <div></div>
            <div></div>
            <div class="text-center">Closed</div>
            <div class="grid content-center justify-center">Monday</div>
            <.input field={@form[:mondayo2]} type="time" label="" />
            <.input field={@form[:mondayc2]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:monday2closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Tuesday</div>
            <.input field={@form[:tuesdayo2]} type="time" label="" />
            <.input field={@form[:tuesdayc2]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:tuesday2closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Wednesday</div>
            <.input field={@form[:wednesdayo2]} type="time" label="" />
            <.input field={@form[:wednesdayc2]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:wednesday2closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Thursday</div>
            <.input field={@form[:thursdayo2]} type="time" label="" />
            <.input field={@form[:thursdayc2]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:thursday2closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Friday</div>
            <.input field={@form[:fridayo2]} type="time" label="" />
            <.input field={@form[:fridayc2]} type="time" label="" />
            <div class=" m-auto">
              <.input field={@form[:friday2closed]} type="checkbox" label="" />
            </div>
            <div class="grid content-center justify-center">Saturday</div>
            <.input field={@form[:saturdayo2]} type="time" label="" />
            <.input field={@form[:saturdayc2]} type="time" label="" />
            <div></div>
            <div class="grid content-center justify-center col-span-2">Show Saturday:</div>
            <div class=" m-auto">
              <.input field={@form[:showsaturday2]} type="checkbox" label="" />
            </div>
            <div></div>
            <div></div>
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
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(Shopinfo.change_slideshow(slideshow))}
  end

  @impl true
  def handle_event("validate", %{"slideshow" => slideshow_params} = params, socket) do
    slideshow_params = case String.contains?(Enum.at(params["_target"], 1), "closed") do
      true ->
        toggle_closed_hours(Enum.at(params["_target"], 1), slideshow_params)
        |> combine_hours()
      false -> slideshow_params
    end
    changeset =
      socket.assigns.slideshow
      |> Shopinfo.change_slideshow(slideshow_params)
      |> Map.put(:action, :validate)
    {:noreply, assign_form(socket, changeset)}
  end

  def toggle_closed_hours(day, params) do

    case Map.get(params, day) do
      "true" ->
        cond do
          String.contains?(day, "1") -> #week 1
            cond do
              String.contains?(day, "monday") -> set_closed_hours("monday", "1", params)
              String.contains?(day, "tuesday") -> set_closed_hours("tuesday", "1", params)
              String.contains?(day, "wednesday") -> set_closed_hours("wednesday", "1", params)
              String.contains?(day, "thursday") -> set_closed_hours("thursday", "1", params)
              String.contains?(day, "friday") -> set_closed_hours("friday", "1", params)
            end
          String.contains?(day, "2") -> #week 2
            cond do
              String.contains?(day, "monday") -> set_closed_hours("monday", "2", params)
              String.contains?(day, "tuesday") -> set_closed_hours("tuesday", "2", params)
              String.contains?(day, "wednesday") -> set_closed_hours("wednesday", "2", params)
              String.contains?(day, "thursday") -> set_closed_hours("thursday", "2", params)
              String.contains?(day, "friday") -> set_closed_hours("friday", "2", params)
            end
        end
      "false" ->
        cond do
          String.contains?(day, "1") -> #week 1
            cond do
              String.contains?(day, "monday") -> set_open_hours("monday", "1", params)
              String.contains?(day, "tuesday") -> set_open_hours("tuesday", "1", params)
              String.contains?(day, "wednesday") -> set_open_hours("wednesday", "1", params)
              String.contains?(day, "thursday") -> set_open_hours("thursday", "1", params)
              String.contains?(day, "friday") -> set_open_hours("friday", "1", params)
            end
          String.contains?(day, "2") -> #week 2
            cond do
              String.contains?(day, "monday") -> set_open_hours("monday", "2", params)
              String.contains?(day, "tuesday") -> set_open_hours("tuesday", "2", params)
              String.contains?(day, "wednesday") -> set_open_hours("wednesday", "2", params)
              String.contains?(day, "thursday") -> set_open_hours("thursday", "2", params)
              String.contains?(day, "friday") -> set_open_hours("friday", "2", params)
            end
        end
    end
  end
  def set_closed_hours(day, week, params) do
    open = "#{day}o#{week}"
    close = "#{day}c#{week}"
    params = Map.put(params, open, "") |> Map.put(close, "")
  end
  def set_open_hours(day, week, params) do
    open = "#{day}o#{week}"
    close = "#{day}c#{week}"
    params = Map.put(params, open, "07:00") |> Map.put(close, "16:00")
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
    socket
  end

  defp combine_hours(slideshow_params) do
    workhours = "#{slideshow_params["mondayo1"]},#{slideshow_params["mondayc1"]},#{slideshow_params["tuesdayo1"]},#{slideshow_params["tuesdayc1"]},#{slideshow_params["wednesdayo1"]},#{slideshow_params["wednesdayc1"]},#{slideshow_params["thursdayo1"]},#{slideshow_params["thursdayc1"]},#{slideshow_params["fridayo1"]},#{slideshow_params["fridayc1"]},#{slideshow_params["saturdayo1"]},#{slideshow_params["saturdayc1"]},#{slideshow_params["mondayo2"]},#{slideshow_params["mondayc2"]},#{slideshow_params["tuesdayo2"]},#{slideshow_params["tuesdayc2"]},#{slideshow_params["wednesdayo2"]},#{slideshow_params["wednesdayc2"]},#{slideshow_params["thursdayo2"]},#{slideshow_params["thursdayc2"]},#{slideshow_params["fridayo2"]},#{slideshow_params["fridayc2"]},#{slideshow_params["saturdayo2"]},#{slideshow_params["saturdayc2"]},#{slideshow_params["showsaturday1"]},#{slideshow_params["showsaturday2"]}"
    Map.put(slideshow_params, "workhours", workhours)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
