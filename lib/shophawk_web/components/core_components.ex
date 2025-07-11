defmodule ShophawkWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such as modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import ShophawkWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/80 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="min-w-[35%] p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def showjob_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/80 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
        phx-hook="Pdf_js_render"
        id="modal-content"
      >
        <div class="flex min-h-screen flex items-start justify-center p-4">
          <div class="min-w-[35%] p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              style="width: 90vw"
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def dark_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/80 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="min-w-[35%] p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-cyan-900 p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def slideshow_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/80 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class=" inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="fixed inset-0 grid place-items-center justify-center">
          <div class="pt-0 pl-1 pr-4">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              style="height: 98vh; width: 98vw"
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-slate-300 p-2 shadow-lg ring-1 transition"
            >
              <div class="absolute top-3 right-3">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="client-error"
      kind={:error}
      title="ShopHawk has been shut down"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>

    <.flash
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 items-center">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def tight_simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class=" items-center">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      >Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-lime-800 hover:bg-lime-700 py-1.5 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def delete_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "hx-submit-loading:opacity-75 rounded-lg bg-neutral-600 hover:bg-red-700 py-1.5 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def info_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "hx-submit-loading:opacity-75 rounded-lg bg-cyan-900 hover:bg-cyan-600 py-1.5 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  attr :link, :string, default: nil

  slot :inner_block, required: true

  def link_button(assigns) do
    ~H"""
    <a
      href={@link}
      target="_blank"
      class={[
        "hx-submit-loading:opacity-75 rounded-lg underline hover:bg-stone-300 px-1",
        "text-xl font-semibold leading-6 text-black hover:text-cyan-800 active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>

    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  attr :link, :string, default: nil

  slot :inner_block, required: true

  def light_link_button(assigns) do
    ~H"""
    <a
      href={@link}
      target="_blank"
      class={[
        "hx-submit-loading:opacity-75 rounded-lg underline px-1 text-white",
        "text-xl font-semibold leading-6 text-black hover:text-stone-900 active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>

    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :department_name, :string, default: nil
  attr :selected_assignment, :string, default: nil
  attr :started_assignment_list, :list, default: []
  attr :selected_value, :string

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week hours_box runlist_assignment_select runlist_department_select)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()

  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-xl leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="h-6 w-6 rounded text-gray-800 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="py-2 block w-full rounded-md border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= for option <- @options do %>
          <option> <%= option %></option>
        <% end %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "runlist_assignment_select"} = assigns) do #Change this this one for assigns selector
    ~H"""
    <div phx-feedback-for={@name}>
      <select
        id={@id}
        name={@name}
        class="block w-full h-10 rounded-md border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-m"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= for option <- @options do %>
          <%= if option == @selected_assignment do %>
            <option selected> <%= option %></option>
          <% else %>
            <%= if option in @started_assignment_list do %>
              <option style="display:none"> <%= option %> </option>
            <% else %>
              <option> <%= option %> </option>
            <% end %>
          <% end %>
        <% end %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "runlist_workcenter_only_assignment_select"} = assigns) do #Change this this one for assigns selector
    ~H"""
    <div phx-feedback-for={@name}>
      <select
        id={@id}
        name={@name}
        class="block w-full h-10 rounded-md border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-m"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= for option <- @options do %>
          <%= if option == @selected_assignment do %>
            <option selected disabled> <%= option %></option>
          <% else %>
            <%= if option in @started_assignment_list do %>
              <option style="display:none"> <%= option %> </option>
            <% else %>
              <option> <%= option %> </option>
            <% end %>
          <% end %>
        <% end %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "runlist_department_select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="py-2 mt-4 block w-full rounded-md border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= for option <- @options do %>
          <%= if option == @department_name do %>
            <option selected> <%= option %></option>
          <% else %>
            <option> <%= option %></option>
          <% end %>
        <% end %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 font-bold text-rose-600 phx-no-feedback:hidden bg-stone-300 rounded-lg m-2">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :width, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-4 sm:w-full">
        <thead class="text-lgleading-6 text-white text-center">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>

          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-200"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-400 text-center">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-cyan-600 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-200"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-lg font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-cyan-500 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-200 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :width, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def compact_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-1 sm:w-full table-fixed">
        <thead class="text-lg leading-6 text-white text-center">
          <tr>
            <th :for={col <- @col} class={["p-0 pr-6 pb-4 font-normal", col[:width]]}><%= col[:label] %></th>

          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-cyan-700 border-t border-cyan-700 text-lg leading-6 text-zinc-200"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class={["group hover:bg-cyan-700 text-center"]}>
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-1 pr-6 truncate">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-cyan-700 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-200"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative p-0">
              <div class="relative whitespace-nowrap py-1 text-right text-lg font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-cyan-700 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-200 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

      @doc ~S"""
  Renders a table with generic styling and an additional attribute for fixed width columns.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id" width="w-40"><%= user.id %></:col>
        <:col :let={user} label="username" width="w-32"><%= user.username %></:col>
      </.table>
  """

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :width, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def fixed_widths_table_with_show_job(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-4 sm:w-full table-fixed">
        <thead class="text-lgleading-6 text-white text-center">
          <tr>
            <th :for={col <- @col} class={["p-0 pr-6 pb-4 font-normal", col[:width]]}><%= col[:label] %></th>

          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-200"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-400 text-center">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              phx-value-job={row.job}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-cyan-700 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-200"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-lg font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-cyan-500 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-200 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def showjob_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-4 sm:w-full">
        <thead class="text-lg leading-6 text-black text-center">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-800"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-300 text-center">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-800"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
              </td>
              <td>
                <%= if String.length(row.operation_note_text) != 0 do %>
                <div class="bg-cyan-800 p-2 w-1 shadow-lg rounded-lg"></div>
                <% end %>
              </td>
              <td class="relative">
                <div class="hidden group-hover:grid fixed bottom-0 right-0 z-50 mb-4 mr-8 p-2 text-white text-md bg-cyan-800 shadow-lg rounded-lg">
                  <%= if row.full_employee_log != [] do %>
                    <%= for row <- row.full_employee_log do %>
                      <%= row %>
                      <br>
                    <% end %>
                  <% end %>
                  <div style="white-space: pre-line;" >
                    <%= if row.operation_note_text != nil, do: String.trim(row.operation_note_text) %>
                  </div>
                </div>
              </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

    @doc ~S"""
  Renders a table specifically with Runlist formatting and layout.  This adds rows to seperate data by date and has custom row colors based on date and # of dots

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :updated, :boolean
  attr :dots, :integer
  attr :weekly_load, :any
  attr :started_assignment_list, :any
  attr :assignments, :any
  attr :jobs_that_ship_today, :any

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :cellstyle, :any
    attr :headerstyle, :any
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def runlist_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
      <div class={["overflow-y-auto px-4 sm:overflow-visible sm:px-0 mt-4", (if rem(@updated, 2) == 1, do: "fade-out", else: "fade-in")]}>
        <div class="bg-cyan-800 p-t-4 rounded-t-lg border-b-4 border-black">
          <%= if @dots != %{} do %>
            <div class={[@dots.dot_columns, "grid text-center pt-3 px-3"]}>
              <%= for {key, title, dot_count} <- [{:one, "Single Dots", 1}, {:two, "Double Dots", 2}, {:three, "Triple Dots", 3}] do %>
                <%= if Map.has_key?(@dots, key) do %>
                  <div class={[@dots[key], "m-1 rounded"]}>
                    <div class="text-lg font-semibold underline">
                      <%= title %>
                    </div>
                    <div :for={op <- Enum.filter(@dots.ops, &(&1.dots == dot_count))}>
                      <div>
                        <%= op.job %> Starting <%= Calendar.strftime(op.sched_start, "%m-%d-%y") %>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          <% end %>

          <%= if @weekly_load do %>
            <div class="grid grid-cols-4 gap-3 pt-3 px-3 rounded-md text-center">
              <%= for {value, week} <- Enum.with_index([@weekly_load.weekone, @weekly_load.weektwo, @weekly_load.weekthree, @weekly_load.weekfour]) do %>
                <div class={[(if rem(@updated, 2) == 1, do: "scale-out-bottom", else: "scale-in-bottom"), ShophawkWeb.RunlistLive.Index.calculate_color(value), "p-1 rounded-t-md border-2 border-black"]}>
                  <%= case week do %>
                    <% 0 -> %> Load for coming week: <%= value %>%
                    <% 1 -> %> Week Two Load: <%= value %>%
                    <% 2 -> %> Week Three Load: <%= value %>%
                    <% 3 -> %> Week Four Load: <%= value %>%
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <div>
        <table class={["w-[40rem] sm:w-full table-fixed"]}>
          <thead class="text-left leading-6 text-stone-200 bg-cyan-800 2xl:text-xl ">
            <tr>
              <th :for={col <- @col} class={["p-0 pr-1 pb-4 font-normal", col[:headerstyle] ]} ><%= col[:label] %></th>
            </tr>
          </thead>
          <tbody
            id={@id}
            phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
            class="relative divide-y divide-stone-800 border-t-0 leading-5 text-stone-200"
          >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class={["group", calc_row_height(row)]}>
            <%= cond do %>
              <% Map.has_key?(elem(row, 1), :ships_today_header) -> %>
                <td colspan="2" class="bg-stone-900"></td>
                <td colspan="9" class="w-full bg-stone-900 text-stone-200 text-center text-2xl"><div class="heartbeat m-1">Scheduled To Ship Today</div></td>
                <td class="bg-stone-900"></td>
              <% Map.has_key?(elem(row, 1), :ships_today) -> %>
                <% exact_wc_vendor = String.replace(elem(row, 1).wc_vendor, " -#{elem(row, 1).operation_service}", "") %>
                <div :for={{col, i} <- Enum.with_index(@col)}>
                  <%= case i do %>
                  <% 8 -> %>
                  <td class={[col[:cellstyle], "relative p-0 text-stone-950", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ "h-12 block" ]} >
                      <form phx-change="change_assignment" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-1 pr-4 pl-4", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status ) ]} >
                          <.input  name="selection" type="runlist_assignment_select" options={@assignments} value="" started_assignment_list={@started_assignment_list} selected_assignment={elem(row, 1).assignment}  />
                        </span>
                      </form>
                    </div>
                  </td>
                  <% 9 -> %>
                  <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ "h-12 text-center block" ]}>
                      <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-3 pr-2 pl-2", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                        <input phx-click="mat_waiting_toggle"
                        phx-value-job-operation={elem(row, 1).job_operation}
                        phx-value-job={elem(row, 1).job}
                        class="h-6 w-6 rounded text-gray-800 focus:ring-0"
                        type="checkbox" id={elem(row, 1).id}
                        checked={elem(row, 1).material_waiting}>
                      </span>
                    </div>
                  </td>
                  <% _ when elem(row, 1).currentop == exact_wc_vendor -> %>
                    <td colspan={if i == 10, do: 2, else: nil} class={[col[:cellstyle], i == 11 && "hidden", "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <div class={[ ]}>
                            <%= if i == 10 do %>
                              &#x2705 Job at <%= elem(row, 1).wc_vendor %>
                            <% else %>
                              <%= render_slot(col, @row_item.(row)) %>
                            <% end %>
                          </div>
                        </span>
                      </div>
                    </td>
                  <% _ -> %>
                    <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <%= render_slot(col, @row_item.(row)) %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                </div>
              <% Map.has_key?(elem(row, 1), :ships_today_footer) -> %>
                <td colspan="12" class="bg-stone-900 h-2"></td>
              <% Map.has_key?(elem(row, 1), :shipping_today) -> %>
                <td colspan="1" class={["relative p-0 text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative font-semibold"]}>
                      <%= elem(row, 1).job %>
                    </span>
                  </div>
                </td>
                <td colspan="1" class={["relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                      <%= elem(row, 1).order_quantity %>
                    </span>
                  </div>
                </td>
                <td colspan="1" class={["relative p-0  text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                      <%= elem(row, 1).est_total_hrs %>
                    </span>
                  </div>
                </td>
                <td colspan="8" class={["relative p-0 text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                    Shipping Today, See Top of List
                    </span>
                  </div>
                </td>
                <td class={["relative p-0 text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                    </span>
                  </div>
                </td>
              <% elem(row, 1).date_row_identifer == 0 -> %> <.render_date_row row={elem(row, 1)} col={@col} />
              <% elem(row, 1).runner == true -> %> <!-- normal operation row -->
                <% exact_wc_vendor = String.replace(elem(row, 1).wc_vendor, " -#{elem(row, 1).operation_service}", "") %>
                <div :for={{col, i} <- Enum.with_index(@col)}>
                  <%= case i do %>
                  <% 8 -> %>
                  <td class={[col[:cellstyle], "relative p-0 text-stone-950", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ "block" ]} >
                      <form phx-change="change_assignment" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-1 pr-4 pl-4", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status ) ]} >
                          <div class="bg-stone-300 rounded">
                            <%= if elem(row, 1).assignment != nil, do: elem(row, 1).assignment, else: " " %>
                          </div>
                        </span>
                      </form>
                    </div>
                  </td>
                  <% 9 -> %>
                  <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={["text-center block"]}>
                      <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-1 pr-2 pl-2", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                        <input phx-click="mat_waiting_toggle" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} class="w-6 rounded text-gray-800 focus:ring-0" type="checkbox" id={elem(row, 1).id} checked={elem(row, 1).material_waiting}>
                      </span>
                    </div>
                  </td>
                  <% _ when elem(row, 1).currentop == exact_wc_vendor -> %>
                    <td colspan={if i == 10, do: 2, else: nil} class={[col[:cellstyle], i == 11 && "hidden", "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={[" block py-1 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <div class={[ ]}>
                            <%= if i == 10 do %>
                              &#x2705 Job at <%= elem(row, 1).wc_vendor %>
                            <% else %>
                              <%= render_slot(col, @row_item.(row)) %>
                            <% end %>
                          </div>
                        </span>
                      </div>
                    </td>
                  <% _ -> %>
                    <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={[" block py-1 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <%= render_slot(col, @row_item.(row)) %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                </div>
              <% true -> %> <!-- normal operation row -->
                <% exact_wc_vendor = String.replace(elem(row, 1).wc_vendor, " -#{elem(row, 1).operation_service}", "") %>
                <div :for={{col, i} <- Enum.with_index(@col)}>
                  <%= case i do %>
                  <% 8 -> %>
                  <td class={[col[:cellstyle], "relative p-0 text-stone-950", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ "block" ]} >
                      <form phx-change="change_assignment" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-1 pr-4 pl-4", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status ) ]} >
                          <.input  name="selection" type="runlist_assignment_select" options={@assignments} value="" started_assignment_list={@started_assignment_list} selected_assignment={elem(row, 1).assignment}/>
                        </span>
                      </form>
                    </div>
                  </td>
                  <% 9 -> %>
                  <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ " text-center block" ]}>
                      <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-3 pr-2 pl-2", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                        <input phx-click="mat_waiting_toggle" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} class=" h-6 w-6 rounded text-gray-800 focus:ring-0" type="checkbox" id={elem(row, 1).id} checked={elem(row, 1).material_waiting}>
                      </span>
                    </div>
                  </td>
                  <% _ when elem(row, 1).currentop == exact_wc_vendor -> %>
                    <td colspan={if i == 10, do: 2, else: nil} class={[col[:cellstyle], i == 11 && "hidden", "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={[" block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <div class={[ ]}>
                            <%= if i == 10 do %>
                              &#x2705 Job at <%= elem(row, 1).wc_vendor %>
                            <% else %>
                              <%= render_slot(col, @row_item.(row)) %>
                            <% end %>
                          </div>
                        </span>
                      </div>
                    </td>
                  <% _ -> %>
                    <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={[" block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <%= render_slot(col, @row_item.(row)) %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                </div>
              <% end %>
            </tr>
          </tbody>
        </table>
        </div>
      </div>
    """
  end

  def calc_row_height(row) do
    cond do
      elem(row, 1).date_row_identifer == 0 -> "h-6"
      elem(row, 1).runner == true -> "h-6"
      elem(row, 1).status == "S" -> "h-6"
      Map.has_key?(elem(row, 1), :ships_today_footer) -> "h-2"
      true -> "h-12"
    end
  end

  def render_date_row(assigns) do
    ~H"""
      <td :for={{_col, i} <- Enum.with_index(@col)} class="bg-stone-300">
        <span class={["font-semibold text-zinc-900"]}>
          <%= case i do %>
            <% 0 -> %> <%= Calendar.strftime(@row.sched_start, "%m-%d-%y") %>
            <% 2 -> %> <%= if Map.has_key?(@row, :est_total_hrs), do: "~#{@row.est_total_hrs}" %>
            <% 3 -> %> Hours of Work <%= if Map.has_key?(@row, :hour_percentage), do: if(is_binary(@row.hour_percentage), do: "(" <> @row.hour_percentage <> "%)") %>
            <% _ -> %> <div></div>
          <% end %>
        </span>
      </td>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :updated, :boolean
  attr :dots, :integer
  attr :weekly_load, :any
  attr :started_assignment_list, :any
  attr :assignments, :any
  attr :jobs_that_ship_today, :any

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :cellstyle, :any
    attr :headerstyle, :any
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def runlist_table_workcenter_only(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
      <div class={["overflow-y-auto px-4 sm:overflow-visible sm:px-0 mt-4", (if rem(@updated, 2) == 1, do: "fade-out", else: "fade-in")]}>
        <div class="bg-cyan-800 p-t-4 rounded-t-lg border-b-4 border-black">
          <%= if @dots != %{} do %>
            <div class={[@dots.dot_columns, "grid text-center pt-3 px-3"]}>
              <%= if Map.has_key?(@dots, :one) do %>
                <div class={[@dots.one, "m-1 rounded"]}>
                  <div class="text-lg font-semibold underline">
                  Single Dots
                  </div>
                  <div :for={op <- Enum.filter(@dots.ops, &(&1.dots == 1))}>
                    <div><%= op.job %> Starting <%= Calendar.strftime(op.sched_start, "%m-%d-%y") %></div>
                  </div>
                </div>
              <% end %>
              <%= if Map.has_key?(@dots, :two) do %>
                <div class={[@dots.two, "m-1 rounded"]}>
                  <div class="text-lg font-semibold underline">
                  Double Dots
                  </div>
                  <div :for={op <- Enum.filter(@dots.ops, &(&1.dots == 2))}>
                    <div><%= op.job %> Starting <%= Calendar.strftime(op.sched_start, "%m-%d-%y") %>
                    </div>
                  </div>
                </div>
              <% end %>
              <%= if Map.has_key?(@dots, :three) do %>
                <div class={[@dots.three, "m-1 rounded"]}>
                  <div class="text-lg font-semibold underline">
                  Triple Dots
                  </div>
                  <div :for={op <- Enum.filter(@dots.ops, &(&1.dots == 3))}>
                    <div><%= op.job %> Starting <%= Calendar.strftime(op.sched_start, "%m-%d-%y") %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
            <div class="grid grid-cols-4 gap-3 pt-3 px-3 rounded-md text-center">

            </div>
        </div>

        <div>
        <table class={["w-[40rem] sm:w-full table-fixed"]}>
          <thead class="text-left leading-6 text-stone-200 bg-cyan-800 2xl:text-xl ">
            <tr>
              <th :for={col <- @col} class={["p-0 pr-1 pb-4 font-normal", col[:headerstyle] ]} ><%= col[:label] %></th>
            </tr>
          </thead>
          <tbody
            id={@id}
            phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
            class="relative divide-y divide-stone-800 border-t-0 leading-5 text-stone-200"
          >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group">
            <%= cond do %>
              <% Map.has_key?(elem(row, 1), :ships_today_header) -> %>
                <td colspan="2" class="bg-stone-900"></td>
                <td colspan="9" class="w-full bg-stone-900 text-stone-200 text-center text-2xl"><div class="heartbeat m-1">Scheduled To Ship Today</div></td>
                <td class="bg-stone-900"></td>
              <% Map.has_key?(elem(row, 1), :ships_today) -> %>
                <% exact_wc_vendor = String.replace(elem(row, 1).wc_vendor, " -#{elem(row, 1).operation_service}", "") %>
                <div :for={{col, i} <- Enum.with_index(@col)}>
                  <%= case i do %>
                  <% 8 -> %>
                  <td class={[col[:cellstyle], "relative p-0 text-stone-950", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ "h-12 block" ]} >
                      <form phx-change="change_assignment" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-1 pr-4 pl-4", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status ) ]} >
                          <.input  name="selection" type="runlist_assignment_select" options={@assignments} value="" started_assignment_list={@started_assignment_list} selected_assignment={elem(row, 1).assignment}  />
                        </span>
                      </form>
                    </div>
                  </td>
                  <% 9 -> %>
                  <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                    <div class={[ "h-12 text-center block" ]}>
                      <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-3 pr-2 pl-2", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                        <input phx-click="mat_waiting_toggle" phx-value-={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} class="h-6 w-6 rounded text-gray-800 focus:ring-0" type="checkbox" id={elem(row, 1).id} checked={elem(row, 1).material_waiting}>
                      </span>
                    </div>
                  </td>
                  <% _ when elem(row, 1).currentop == exact_wc_vendor -> %>
                    <td colspan={if i == 10, do: 2, else: nil} class={[col[:cellstyle], i == 11 && "hidden", "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <div class={[ ]}>
                            <%= if i == 10 do %>
                              &#x2705 Job at <%= elem(row, 1).wc_vendor %>
                            <% else %>
                              <%= render_slot(col, @row_item.(row)) %>
                            <% end %>
                          </div>
                        </span>
                      </div>
                    </td>
                  <% _ -> %>
                    <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <%= render_slot(col, @row_item.(row)) %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                </div>
              <% Map.has_key?(elem(row, 1), :ships_today_footer) -> %>
                <td colspan="12" class="bg-stone-900 h-2"></td>
              <% Map.has_key?(elem(row, 1), :shipping_today) -> %>
                <td colspan="1" class={["relative p-0 text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative font-semibold"]}>
                      <%= elem(row, 1).job %>
                    </span>
                  </div>
                </td>
                <td colspan="1" class={["relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                      <%= elem(row, 1).order_quantity %>
                    </span>
                  </div>
                </td>
                <td colspan="1" class={["relative p-0  text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                      <%= elem(row, 1).est_total_hrs %>
                    </span>
                  </div>
                </td>
                <td colspan="8" class={["relative p-0 text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                    Shipping Today, See Top of List
                    </span>
                  </div>
                </td>
                <td class={["relative p-0 text-center", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                  <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                    <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                    <span class={["relative"]}>
                    </span>
                  </div>
                </td>

              <% elem(row, 1).date_row_identifer == 0 -> %>

                <td :for={{_col, i} <- Enum.with_index(@col)}
                class={["bg-stone-300"]}
                colspan="">
                <div class="h-6">
                  <%= case i do %>
                  <% 0 -> %>
                    <span class={["font-semibold text-zinc-900"]}>
                    <%= Calendar.strftime(elem(row, 1).sched_start, "%m-%d-%y") %>
                    </span>
                  <% 2 -> %>
                    <span class={["font-semibold text-zinc-900"]}>
                    <%= if Map.has_key?(elem(row, 1), :est_total_hrs) do %>
                      ~<%= elem(row, 1).est_total_hrs %>
                    <% end %>
                    </span>
                  <% 3 -> %>
                    <span class={["font-semibold text-zinc-900"]}>
                    Hours of Work <%= if Map.has_key?(elem(row, 1), :hour_percentage), do: "(" <> elem(row, 1).hour_percentage <> "%)" %>
                  </span>
                  <% _ -> %>
                    <div></div>
                  <% end %>
                  </div>
                </td>

              <% true -> %>

                <% exact_wc_vendor = String.replace(elem(row, 1).wc_vendor, " -#{elem(row, 1).operation_service}", "") %>

                <div :for={{col, i} <- Enum.with_index(@col)}>
                  <%= case i do %>
                  <% 8 -> %>
                    <td class={[col[:cellstyle], "relative p-0 text-stone-950", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={[ "h-12 block" ]} >
                        <form phx-change="change_assignment" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} >
                          <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-1 pr-4 pl-4", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status ) ]} >
                            <.input  name="selection" type="runlist_assignment_select" options={@assignments} value="" started_assignment_list={@started_assignment_list} selected_assignment={elem(row, 1).assignment}  />
                          </span>
                        </form>
                      </div>
                    </td>
                  <% 9 -> %>
                    <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={[ "h-12 text-center block" ]}>
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl py-3 pr-2 pl-2", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                          <input phx-click="mat_waiting_toggle" phx-value-job-operation={elem(row, 1).job_operation} phx-value-job={elem(row, 1).job} class="h-6 w-6 rounded text-gray-800 focus:ring-0" type="checkbox" id={elem(row, 1).id} checked={elem(row, 1).material_waiting}>
                        </span>
                      </div>
                    </td>
                  <% _ when elem(row, 1).currentop == exact_wc_vendor -> %>
                    <td colspan={if i == 10, do: 2, else: nil} class={[col[:cellstyle], i == 11 && "hidden", "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <div class={[ ]}>
                            <%= if i == 10 do %>
                              &#x2705 Job at <%= elem(row, 1).wc_vendor %>
                            <% else %>
                              <%= render_slot(col, @row_item.(row)) %>
                            <% end %>
                          </div>
                        </span>
                      </div>
                    </td>
                  <% _ -> %>
                    <td class={[col[:cellstyle], "relative p-0", @row_click && "hover:cursor-pointer", date_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} >
                      <div class={["h-12 block py-3 pr-2 pl-2 truncate"]} phx-click={@row_click && @row_click.(row)} phx-value-job={elem(row, 1).job} >
                        <span class={["absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl", hover_color(elem(row, 1).sched_start, elem(row, 1).dots, elem(row, 1).runner, elem(row, 1).status) ]} />
                        <span class={["relative", i == 0 && "font-semibold"]}>
                          <%= render_slot(col, @row_item.(row)) %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                </div>
              <% end %>
            </tr>
          </tbody>
        </table>
        </div>
      </div>
      """
    end

  defp date_color(date, dots, runner, status) do
    color =
      case Date.compare(date, Date.utc_today()) do
        :lt -> "bg-rose-200 text-stone-950"
        :eq -> "bg-sky-200 text-stone-950"
        :gt -> "bg-cyan-800"
      end

    color =  if status == "Started", do: "bg-emerald-500 text-stone-950", else: color
    color = case dots do
      1 -> "bg-cyan-500 text-stone-950"
      2 -> "bg-amber-500 text-stone-950"
      3 -> "bg-red-600 text-stone-950"
      _ -> color
    end
    if runner == true, do: "bg-cyan-900", else: color
  end

  defp hover_color(date, dots, runner, status) do
    color =
      case Date.compare(date, Date.utc_today()) do
        :lt -> "group-hover:bg-rose-100"
        :eq -> "group-hover:bg-sky-100"
        :gt -> "group-hover:bg-cyan-700"
      end

    color =  if status == "S", do: "group-hover:bg-emerald-400 text-stone-950", else: color
    color = case dots do
      1 -> "group-hover:bg-cyan-400"
      2 -> "group-hover:bg-amber-400"
      3 -> "group-hover:bg-red-500"
      _ -> color
    end
    if runner == true, do: "group-hover:bg-cyan-950", else: color
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}", time: 10) #time not working here? trying to speed up total transition
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-10", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ShophawkWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ShophawkWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
