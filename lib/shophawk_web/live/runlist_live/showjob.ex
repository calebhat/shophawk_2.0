defmodule ShophawkWeb.RunlistLive.ShowJob do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  #JS.navigate(~p"/runlists/#{runlist}")  Show one runlist item.

  def render(assigns) do
    ~H"""
      <div class="">
      <div class="text-2xl text-black text-center underline">
      <%= assigns.job %>
      </div>
      <div class="text-lg text-center border-b-4 border-zinc-400 p-6">
        <div class="grid grid-cols-3 grid-rows-5">
          <div class="underline text-base">Part</div>
          <div class="underline text-base">Qty</div>
          <div class="underline text-base">Customer </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.part_number %> </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.order_quantity %> </div>
          <div class="text-lg row-span-2"><%= assigns.job_info.customer %> </div>

          <div class="underline text-base">Description</div>
          <div class="underline text-base">material</div>
          <div class="underline text-base">Custmoer PO </div>
          <div class="text-lg"><%= assigns.job_info.description %> </div>
          <div class="text-lg"><%= assigns.job_info.material %> </div>
          <div class="text-lg"><%= assigns.job_info.customer_po <> ", line: " <> assigns.job_info.customer_po_line %> </div>

        </div>
      </div>

      <.table id={@job} rows={@job_ops}>
        <:col :let={op} label="Operation"><%= op.wc_vendor %><%= op.operation_service %></:col>
        <:col :let={op} label="Start Date"><%= op.sched_start %></:col>
        <:col :let={op} label="Total Hours"><%= op.est_total_hrs %></:col>
        <:col :let={op} label="Status"><%= op.status %></:col>
        <:col :let={op} label="Operator"><%= op.employee %></:col>
      </.table>

      </div>
    """
  end


  def update(assigns, socket) do
    #IO.inspect(assigns)

    {:ok,
    socket
    |> assign(job: assigns.id)
    |> assign(job_ops: assigns.job_ops)
    |> assign(job_info: assigns.job_info)}
  end

end
