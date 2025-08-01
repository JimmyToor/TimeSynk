import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  static targets = ["stream"];

  streamTargetConnected(newStreamElement) {
    const newStreamName = newStreamElement.getAttribute("signed-stream-name");
    this.streamTargets.some((streamElement) => {
      if (
        streamElement.getAttribute("signed-stream-name") === newStreamName &&
        newStreamElement !== streamElement
      ) {
        // The disconnect callback won't be called if we remove the element immediately,
        // so we need to delay the removal.
        setTimeout(() => {
          newStreamElement.remove();
        }, 0);

        return true;
      }
    });
  }
}
