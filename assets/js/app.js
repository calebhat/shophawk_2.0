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

// Register hooks with LiveSocket
let Hooks = {
  ...ChartHooks,
  AutofocusHook,
  StandAloneInputboxChange,
  ResetForm
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

