defmodule ShophawkWeb.Router do
  use ShophawkWeb, :router

  import ShophawkWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShophawkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShophawkWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/download/:file_path", DownloadController, :download

    live "/information", InformationLive.Index, :index

    live "/tools", ToolLive.Index, :index
    live "/tools/new", ToolLive.Index, :new
    live "/tools/:id/edit", ToolLive.Index, :edit
    live "/tools/:id/checkout", ToolLive.Index, :checkout
    live "/tools/:id/checkin", ToolLive.Index, :checkin
    live "/tools/restock", ToolLive.Index, :restock
    live "/tools/:id", ToolLive.Show, :show
    live "/tools/:id/show/edit", ToolLive.Show, :edit

    live "/runlists/:id/job", RunlistLive.ShowJob, :showjob
    live "/runlists/new_department", RunlistLive.Index, :new_department
    live "/runlists/:id/edit_department", RunlistLive.Index, :edit_department
    live "/runlists/:id/new_assignment", RunlistLive.Index, :new_assignment
    live "/runlists/:id/assignments", RunlistLive.Index, :assignments
    live "/runlists", RunlistLive.Index, :index
    live "/runlists/:id", RunlistLive.Show, :show
    live "/runlists/:id/show/edit", RunlistLive.Show, :edit
    live "/runlists/importall", RunlistLive.Importall, :importall

    live "/departments", DepartmentLive.Index, :index
    live "/departments/new", DepartmentLive.Index, :new_department
    live "/departments/:id/edit", DepartmentLive.Index, :edit_department
    live "/departments/:id", DepartmentLive.Show, :show
    live "/departments/:id/show/edit", DepartmentLive.Show, :edit

    live "/slideshow", SlideshowLive.Index, :index
    live "/slideshow/new", SlideshowLive.Index, :new
    live "/slideshow/:id/edit", SlideshowLive.Index, :edit
    live "/run_slideshow/:id", SlideshowLive.Index, :run_slideshow
    live "/slideshow/:id", SlideshowLive.Show, :show
    live "/slideshow/:id/show/edit", SlideshowLive.Show, :edit

    live "/timeoff", TimeoffLive.Index, :index
    live "/timeoff/new", TimeoffLive.Index, :new
    live "/timeoff/:id/edit", TimeoffLive.Index, :edit
    live "/timeoff/:id", TimeoffLive.Show, :show
    live "/timeoff/:id/show/edit", TimeoffLive.Show, :edit

    live "/dashboard/shop_meeting", DashboardLive.ShopMeeting, :index

  end

  # Other scopes may use custom stacks.
  # scope "/api", ShophawkWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:shophawk, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/devdashboard", metrics: ShophawkWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ShophawkWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ShophawkWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ShophawkWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ShophawkWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/dashboard", DashboardLive.Index, :index
      live "/dashboard/accounting", DashboardLive.Accounting, :index
      live "/dashboard/office", DashboardLive.Office, :index

    end
  end

  scope "/", ShophawkWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ShophawkWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
