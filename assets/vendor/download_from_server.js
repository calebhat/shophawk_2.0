window.addEventListener("phx:trigger_file_download", (event) => {
  console.log(event.detail.url);
    const url = event.detail.url;
    const link = document.createElement("a");
    link.href = url;
    link.download = ""; // Optional: specify a filename if needed
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  });
  
  