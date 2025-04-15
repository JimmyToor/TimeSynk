import { Turbo } from "@hotwired/turbo-rails";
Turbo.StreamActions.frame_reload = function () {
  document.querySelectorAll(`turbo-frame#${this.target}`).forEach((frame) => {
    frame.src = frame.src || frame.dataset.src;
  });
};
