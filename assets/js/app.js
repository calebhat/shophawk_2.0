// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

import * as pdfjsLib from "pdfjs-dist/build/pdf.mjs";
pdfjsLib.GlobalWorkerOptions.workerSrc = "/js/pdfjs-dist/pdf.worker.min.mjs"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import "../vendor/download_from_server"; //handles file downloads from push_redirect function inside a liveview

// Import the chart hooks from charts.js
import ChartHooks from "./charts";

let AutofocusHook = {
  mounted() {
    setTimeout(() => {
      document.activeElement.blur();
      this.el.focus();
    }, 1); // Small delay to ensure element is ready
    this.handleEvent("trigger_autofocus", ({ target_id }) => {
      if (target_id === this.el.id) {
        setTimeout(() => {
          document.activeElement.blur();
          this.el.focus();
        }, 1); // Focus only if this element's ID matches
      }
    });
  }
};

let StandAloneInputboxChange = {
  mounted() {
    this.el.addEventListener("input", (e) => {
      this.pushEvent("save_comment", {
        input: e.target.value,
        id: this.el.id });
    });
  }
}

let ResetForm = { //trigger with push_event(socket, "reset_form", %{})
  mounted() {
    this.handleEvent("reset_form", () => {
      this.el.reset(); // Resets the form to its initial state
    });
  }
}

let Pdf_js_render = 
  {
    mounted() {
      console.log("ModalScrollControl mounted on:", this.el.id);
      console.log("Is scrollable?", getComputedStyle(this.el).overflowY);
  
      // Capture initial scroll position
      const initialScrollPosition = this.el.scrollTop;
  
      const canvases = this.el.querySelectorAll("canvas[data-pdf-path]");
      console.log("Found canvases:", canvases.length);
  
      // Collect all render promises
      const renderPromises = Array.from(canvases).map((canvas, index) => {
        const pdfPath = canvas.getAttribute("data-pdf-path");
        console.log(`Loading PDF ${index}:`, pdfPath);
  
        // Store state for each canvas
        const state = {
          pdf: null,
          currentPage: 1,
          scale: 1.0,
          rotation: 0,
        };
  
        // Render PDF page
        const renderPage = (pageNum, scale, rotation, fitToContainer = true) => {
          return pdfjsLib.getDocument(pdfPath).promise.then((pdf) => {
            state.pdf = pdf;
            state.numPages = pdf.numPages;
            return pdf.getPage(pageNum).then((page) => {
              const baseViewport = page.getViewport({ scale: 1.0, rotation: 0 });
              const isPortrait = baseViewport.width < baseViewport.height;
              const effectiveRotation = isPortrait ? 90 : 0;
              const totalRotation = rotation + effectiveRotation;
  
              let viewport = page.getViewport({ scale: 1.0, rotation: totalRotation });
              let finalScale = scale;
              if (fitToContainer) {
                const containerWidth = canvas.parentElement.clientWidth;
                finalScale = (containerWidth / viewport.width) * 0.95;
                state.scale = finalScale;
              }
  
              viewport = page.getViewport({ scale: finalScale, rotation: totalRotation });
  
              canvas.width = viewport.width;
              canvas.height = viewport.height;
              canvas.style.width = `${viewport.width}px`;
              canvas.style.height = `${viewport.height}px`;
  
              return page.render({
                canvasContext: canvas.getContext("2d"),
                viewport: viewport,
              }).promise.then(() => {
                console.log(`PDF ${index} rendered: page ${pageNum}, scale ${finalScale}, rotation ${totalRotation}`);
  
                // Update page number display
                const pageDisplay = canvas.parentElement.parentElement.querySelector(".page-display");
                if (pageDisplay) {
                  pageDisplay.textContent = `Page ${state.currentPage} of ${state.numPages}`;
                }
              }).catch((error) => {
                console.error(`Render error for ${pdfPath}:`, error);
              });
            }).catch((error) => {
              console.error(`Page load error for ${pdfPath}:`, error);
            });
          }).catch((error) => {
            console.error(`PDF load error for ${pdfPath}:`, error);
          });
        };
  
        // Initial render with fit-to-container
        return renderPage(state.currentPage, state.scale, state.rotation, true).then(() => {
          // Add event listeners for controls
          const controls = canvas.parentElement.parentElement.querySelector(".pdf-controls");
          if (controls) {
            console.log(`Found controls for canvas ${index}`);
            controls.querySelector(".prev-page").addEventListener("click", (event) => {
              event.preventDefault();
              if (state.currentPage > 1) {
                state.currentPage -= 1;
                renderPage(state.currentPage, state.scale, state.rotation, false);
              }
            });
  
            controls.querySelector(".next-page").addEventListener("click", (event) => {
              event.preventDefault();
              if (state.currentPage < state.numPages) {
                state.currentPage += 1;
                renderPage(state.currentPage, state.scale, state.rotation, false);
              }
            });
  
            controls.querySelector(".zoom-in").addEventListener("click", (event) => {
              event.preventDefault();
              state.scale += 0.2;
              renderPage(state.currentPage, state.scale, state.rotation, false);
            });
  
            controls.querySelector(".zoom-out").addEventListener("click", (event) => {
              event.preventDefault();
              if (state.scale > 0.2) {
                state.scale -= 0.2;
                renderPage(state.currentPage, state.scale, state.rotation, false);
              }
            });
  
            controls.querySelector(".rotate").addEventListener("click", (event) => {
              event.preventDefault();
              state.rotation = (state.rotation + 90) % 360;
              renderPage(state.currentPage, state.scale, state.rotation, false);
            });
  
            controls.querySelector(".fit-to-container").addEventListener("click", (event) => {
              event.preventDefault();
              renderPage(state.currentPage, state.scale, state.rotation, true);
            });
  
            // Note: No JavaScript event listener needed for download as we're using an <a> tag with download attribute
          } else {
            console.error(`Controls not found for canvas ${index}`);
          }
        });
      });
  
      // Restore scroll position after all PDFs are rendered
      Promise.all(renderPromises).then(() => {
        console.log("All PDFs rendered");
      }).catch((error) => {
        console.error("Error rendering PDFs:", error);
      });
    }
  
  }

// Register hooks with LiveSocket
let Hooks = {
  ...ChartHooks,
  AutofocusHook,
  StandAloneInputboxChange,
  ResetForm,
  Pdf_js_render
}; // Merge hooks


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

