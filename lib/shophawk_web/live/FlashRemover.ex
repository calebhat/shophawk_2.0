# lib/shophawk_web/flash_handler.ex
defmodule ShophawkWeb.FlashRemover do
  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_info(:clear_flash, socket) do
        {:noreply, clear_flash(socket)}
      end
    end
  end
end
