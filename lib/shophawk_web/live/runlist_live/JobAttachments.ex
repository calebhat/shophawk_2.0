defmodule ShophawkWeb.RunlistLive.JobAttachments do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
      <div>
        <div class="text-center text-black p-6" >
          <div class="text-2xl underline"><%= assigns.job %> Attachments </div>
          <div class="text-base">(Click to Download) </div>
        </div>
        <%= if Map.has_key?(assigns, :not_found) do %>
          <div class="text-red"> File Not Found </div>
        <% end %>

        <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
          <table class="w-[40rem] mt-4 sm:w-full">
            <thead class="text-lg text-left leading-6 text-black text-center">
              <tr>
                <th class="p-0 pr-6 pb-4 font-normal">Description/Part #</th>
                <th class="p-0 pr-6 pb-4 font-normal">Server Location</th>
              </tr>
            </thead>
            <tbody
              id={@job}
              class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-800"
            >
              <tr :for={attachment <- @attachments} class="group hover:bg-zinc-400 text-center">
                <td class={["relative p-0 hover:cursor-pointer"]} phx-click="download" phx-data-file-path={attachment.path} >
                  <div class="block py-4 pr-6">
                    <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-300 sm:rounded-l-xl" />
                    <span class={["relative font-semibold text-zinc-800"]}>
                      <%= attachment.description %>
                    </span>
                  </div>
                </td>
                <td class={["relative p-0 hover:cursor-pointer"]} phx-click="download" phx-value-file-path={attachment.path} >
                  <div class="block py-4 pr-6">
                    <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-300 sm:rounded-l-xl" />
                    <span class={["relative"]}>
                      <%= attachment.path %>
                    </span>
                  </div>
                </td>

              </tr>
            </tbody>
          </table>
        </div>
      </div>

    """
  end

  def update(assigns, socket) do
    IO.inspect(assigns.attachments)
    {:ok,
    socket
    |> assign(job: assigns.id)
    |> assign(attachments: assigns.attachments)}
  end

end
