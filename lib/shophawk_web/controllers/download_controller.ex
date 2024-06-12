defmodule ShophawkWeb.DownloadController do
  use ShophawkWeb, :controller

  def download(conn, %{"file_path" => file_path}) do
    # Decode the file path if it's URL-encoded
    file_path = URI.decode(file_path) |> String.replace("`", "/") #|> IO.inspect
    # Send the file for download
    send_download(conn, {:file, file_path})
  end
end
