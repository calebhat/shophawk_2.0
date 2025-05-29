defmodule ShophawkWeb.Components.Navbar do
  use Phoenix.LiveComponent
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  import Phoenix.VerifiedRoutes, only: [sigil_p: 2]
  import ShophawkWeb.CoreComponents


  @endpoint ShophawkWeb.Endpoint
  @router ShophawkWeb.Router

  @impl true
  def mount(socket) do
    # Initialize assigns needed for the modal
    {:ok, assign(socket, show_modal: false, action: nil, selected_job: nil, job_ops: nil, job_info: nil, attachments: nil, search_value: "")}
  end

  @impl true
  def render(assigns) do #includes @current_user which is passed from component callout in each liveview.
    ~H"""
      <div>
        <header class="px-4 sm:px-6 lg:px-8 bg-cyan-900">
          <div class="flex items-center justify-between py-3 text-sm">
            <div class="flex items-center gap-4">
              <a href="/">
                <img src={~p"/images/gearhawklogo.jpg"} width="50" />
              </a>
              <a href={~p"/runlists"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                Runlist
              </a>

              <a href={~p"/tools"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                Inventory
              </a>

              <a href={~p"/stockedmaterials"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                Material
              </a>
              <a href={~p"/deliveries"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                Deliveries
              </a>
              <a href={~p"/slideshow"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                Slideshow
              </a>
              <a href={~p"/information"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                Information
              </a>

              <!-- Dropdown Wrapper for Dashboard -->
              <div class="relative group">
                <%= if @current_user do %> <!-- hide drop down unless logged in -->
                  <%= if @current_user.email == "admin" do %>
                      <a href={~p"/dashboard"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                        Dashboard
                      </a>
                    <!-- Dropdown Menu -->
                    <div class="relative" style="z-index: 15">
                      <div class="absolute hidden group-hover:block bg-cyan-800 rounded-lg shadow-lg" style="left: 0;">
                        <div class="flex flex-col">
                          <a href={~p"/dashboard/accounting"} class="block px-4 py-2 text-white hover:bg-cyan-700 hover:rounded-lg">
                            Accounting
                          </a>
                          <a href={~p"/dashboard/employee_performance"} class="block px-4 py-2 text-white hover:bg-cyan-700 hover:rounded-lg">
                            Employee Performance
                          </a>
                        </div>
                      </div>
                    </div>
                  <% end %>
                  <%= if @current_user.email == "office" do %>
                    <a href={~p"/dashboard/office"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                      Dashboard
                    </a>
                  <% end %>
                <% else %>
                  <a href={~p"/dashboard/shop_meeting"} class="text-white text-2xl rounded-lg px-1 py-1 hover:text-stone-400">
                    Dashboard
                  </a>
                <% end %>
              </div>


            </div>

            <ul class="relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
              <form id={"search-form"} phx-submit="show_job" key={@search_value} phx-hook="ResetForm">
                  <.input
                    type="text"
                    name="job"
                    value={@search_value}
                    placeholder="Job Search..."
                  />
                </form>
              <%= if @current_user do %>
                <li class="text-[0.8125rem] leading-6 text-stone-400">
                  <%= @current_user.email %>
                </li>
                <!-- <li>
                  <.link
                    href={~p"/users/settings"}
                    class="text-[0.8125rem] leading-6 text-stone-400 font-semibold hover:text-stone-200"
                  >
                    Settings
                  </.link>
                </li> -->
                <li>
                  <.link
                    href={~p"/users/log_out"}
                    method="delete"
                    class="text-[0.8125rem] leading-6 text-stone-400 font-semibold hover:text-stone-200"
                  >
                    Log out
                  </.link>
                </li>
              <% else %>
                <!-- <li>
                  <.link
                    href={~p"/users/register"}
                    class="text-[0.8125rem] leading-6 text-stone-400 font-semibold hover:text-stone-200"
                  >
                    Register
                  </.link>
                </li> -->
                <li>
                  <.link
                    href={~p"/users/log_in"}
                    class="text-[0.8125rem] leading-6 text-stone-400 font-semibold hover:text-stone-200"
                  >
                    Log in
                  </.link>
                </li>
              <% end %>
            </ul>
          </div>
        </header>

      </div>
    """
  end

end
