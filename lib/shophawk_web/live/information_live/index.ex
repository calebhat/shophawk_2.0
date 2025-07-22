defmodule ShophawkWeb.InformationLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJobLive.ShowJobMacroFunctions #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />
    <div class="px-4 py-4 sm:px-6 lg:px-8">
      <div class="grid grid-cols-3 place-content-center text-stone-100">
        <div class="text-center justify-center rounded-2xl p-4 bg-cyan-900 m-4">
          <div class="text-2xl underline">
            Personal Time
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            Earned by full time employees with no unexcused absenses within each four month time period
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            Any hours earned after 24 will be paid out as a bonus
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            Can be used in 15 minutes increments
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            <table class="w-full table-fixed">
              <tr>
                <th>Date</th>
                <th>Personal Hours Earned</th>
              </tr>
              <tr>
                <td class="border border-stone-400">1/1</td>
                <td class="border border-stone-400">8 Hours</td>
              </tr>
              <tr>
                <td class="border border-stone-400">5/1</td>
                <td class="border border-stone-400">8 Hours</td>
              </tr>
              <tr>
                <td class="border border-stone-400">9/1</td>
                <td class="border border-stone-400">8 Hours</td>
              </tr>
            </table>
          </div>
        </div>
        <div class="text-center justify-center rounded-2xl p-4 bg-cyan-900 m-4">
          <div class="text-2xl underline">
            Vacation
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            Earned by full time employees after every hire anniversay date
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            Can be used in 30 minute increments
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            <table class="w-full">
              <tr>
                <th>Years of Service</th>
                <th>Vacation Days Earned</th>
              </tr>
              <tr>
                <td class="border border-stone-400">1 Year</td>
                <td class="border border-stone-400">5 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">2 Years</td>
                <td class="border border-stone-400">10 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">5 Years</td>
                <td class="border border-stone-400">15 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">10 Years</td>
                <td class="border border-stone-400">16 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">15 Years</td>
                <td class="border border-stone-400">17 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">20 Years</td>
                <td class="border border-stone-400">18 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">25 Years</td>
                <td class="border border-stone-400">19 Days</td>
              </tr>
              <tr>
                <td class="border border-stone-400">30 Years</td>
                <td class="border border-stone-400">20 Days</td>
              </tr>
            </table>
          </div>
        </div>
        <div class="text-center justify-center rounded-2xl p-4 bg-cyan-900 m-4">
          <div class="text-2xl underline">
            Miscellaneous
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            Insurance Payout Dates are 3/1, 6/1, 9/1, 12/1
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            <div>Full Time employees earn 20 hours yearly of paid Volunteer Time.</div>
            <div>ask managment for approval.</div>
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            <div class="text-xl underline mb-2">Paid Holidays</div>
            <div class=" grid grid-cols-3">
              <div class="border border-stone-400">New Years Eve</div>
              <div class="border border-stone-400">New Years Day</div>
              <div class="border border-stone-400">Good Friday</div>
              <div class="border border-stone-400">Memorial Day</div>
              <div class="border border-stone-400">Independance Day</div>
              <div class="border border-stone-400">Labor Day</div>
            </div>
            <div class="grid grid-cols-2">
              <div class="border border-stone-400">Thanksgiving Day</div>
              <div class="border border-stone-400">Day After Thanksgiving</div>
              <div class="border border-stone-400">Christmas Eve</div>
              <div class="border border-stone-400">Christmas Day</div>
            </div>
          </div>
        </div>

        <div  class="text-center justify-center rounded-2xl p-4 bg-cyan-900 m-4">
          <div class="text-2xl underline">
            Commitee Leaders
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            <ul>
              <li>Human Resources: Brent/Greg/Caleb</li>
              <li>Training: Brent</li>
              <li>Future Planning: Nolan</li>
              <li>Party Planning: Nicole</li>
            </ul>
          </div>
        </div>
        <div class="text-center justify-center rounded-2xl p-4 bg-cyan-900 m-4">
          <div class="text-2xl underline">
            Human Resources
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2">
            <div class="text-lg">Primary Contact:</div>
            <div class="grid grid-cols-2">
              <div>Emily Smith</div>
              <div>O: 262-376-3236</div>
              <div>M: 608-769-6031</div>
              <div>E: emily.smith@ansay.com</div>
            </div>
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2 underline">
            <a class="hover:text-stone-900" href="https://access.paylocity.com/" target="_blank">Paylocity Company ID: 177394</a>
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2 underline ">
            <a class="hover:text-stone-900" href="https://accounts.principal.com" target="_blank">Principal Retirement Login</a>
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2 underline hover:text-stone-900">
            <div phx-click="download_file" phx-value-file-path="\\EG-SRV-FP01\Data\General Share folder\shophawk_downloads\Employee_Handbook_EG_2024.pdf">
              <a class="" href="" target="" >
                Download Employee Handbook
              </a>
            </div>
          </div>
          <div class="text-md bg-cyan-800 rounded-2xl m-2 p-2 underline hover:text-stone-900">
            <div phx-click="download_file" phx-value-file-path="\\EG-SRV-FP01\Data\General Share folder\shophawk_downloads\esop_summary_2024.pdf">
              <a class="" href="" target="" >
                Download ESOP Information
              </a>
            </div>
          </div>
        </div>
        <div></div>

      </div>

      <.showjob_modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/information")}>
          <.live_component
              module={ShophawkWeb.ShowJobLive.ShowJob}
              id={@id || :show_job}
              job_ops={@job_ops}
              job_info={@job_info}
              title={@page_title}
              action={@live_action}
              current_user={@current_user}
              expanded={@expanded || []}
          />
        </.showjob_modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Information")
  end

  @impl true
  def handle_event("download_file", %{"file-path" => file_path}, socket) do
    #URL leads to router where I have a JS listener setup to push a file download from the path
    {:noreply, push_event(socket, "trigger_file_download", %{"url" => "/download/#{URI.encode(file_path)}"})}
  end

end
