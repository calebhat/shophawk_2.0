defmodule ShophawkWeb.RunlistLive.ShowJob do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
      <div class="">
      <div class="text-center text-black p-6" >
        <div class="grid grid-cols-3" >
          <div class="text-base"><%= assigns.job_info.job_manager %></div>
          <div class="text-2xl underline"><%= assigns.job %> </div>
          <div><.info_button phx-click="attachments">Attachments</.info_button> </div>
        </div>
      </div>
      <div class="text-lg text-center border-b-4 border-zinc-400 p-6">
        <div class="grid grid-cols-4 grid-rows-3">
          <div class="underline text-base">Part</div>
          <div class="underline text-base">Make</div>
          <div class="underline text-base">Ordered</div>
          <div class="underline text-base">Customer </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.part_number %> </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.make_quantity %> </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.order_quantity %> </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.customer %> </div>
        </div>
        <div class="grid grid-cols-3 grid-rows-2">
          <div class="underline text-base">Description</div>
          <div class="underline text-base">material</div>
          <div class="underline text-base">Customer PO </div>
          <div class="text-lg"><%= assigns.job_info.description %> </div>
          <div class="text-lg"><%= assigns.job_info.material %> </div>
          <div class="text-lg"><%= assigns.job_info.customer_po <> ", line: " <> assigns.job_info.customer_po_line %> </div>

        </div>
      </div>

      <.showjob_table id={@job} rows={@job_ops}>
        <:col :let={op} label="Operation"><%= op.wc_vendor %><%= op.operation_service %></:col>
        <:col :let={op} label="Start Date"><%= op.sched_start %></:col>
        <:col :let={op} label="Total Hours"><%= op.est_total_hrs %></:col>
        <:col :let={op} label="Status"><%= op.status %></:col>
        <:col :let={op} label="Operator"><%= op.employee %></:col>
      </.showjob_table>

      </div>
    """
  end

  def update(assigns, socket) do

    {:ok,
    socket
    |> assign(job: assigns.id)
    |> assign(job_ops: assigns.job_ops)
    |> assign(job_info: assigns.job_info)}
  end

end
