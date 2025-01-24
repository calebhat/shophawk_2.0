defmodule ShophawkWeb.FileSenderController do
  use ShophawkWeb, :controller

  #this is a custom plug used in the "/slideshow_photos" scope from the router.ex file.

  def serve_customer_photo(conn, %{"filename" => filename}) do
    photo_path = Path.join("\\\\EG-SRV-FP01\\Data\\Shophawk\\slideshow_photos", filename)

    if File.exists?(photo_path) do
      conn
      |> put_resp_content_type("image/png")
      |> send_file(200, photo_path)
    else
      conn
      |> send_resp(404, "File not found")
    end
  end
end
