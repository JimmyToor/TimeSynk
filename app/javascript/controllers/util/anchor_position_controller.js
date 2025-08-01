import { Controller } from "@hotwired/stimulus";
// Connects to data-controller="top-layer-position"
// This controller is responsible for positioning an element relative to an anchor element.
// Handy for elements that need to be positioned at the top layer of the page, such as modals or tooltips.
export default class extends Controller {
  static targets = ["positionedElement", "anchor"];
  static values = {
    // The position style to apply to the positioned element, e.g., "fixed", "absolute"
    positionStyle: { type: String, default: null },
  };

  initialize() {
    this.resizeHandler = this.triggerUpdate.bind(this);
    this.resizeObserver = new ResizeObserver(this.resizeHandler);
  }

  connect() {
    window.addEventListener("resize", this.resizeHandler, true);
    // Recalculate position when a screen orientation change occurs
    window
      .matchMedia("(orientation: portrait)")
      .addEventListener("change", this.resizeHandler, true);
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler, true);
    window
      .matchMedia("(orientation: portrait)")
      .removeEventListener("change", this.resizeHandler, true);
    this.resizeObserver.disconnect();
  }

  triggerUpdate() {
    // Request an animation frame to ensure the DOM is updated before recalculating positions
    window.requestAnimationFrame(() => this.updatePosition());
  }

  /**
   * Updates the position of the positioned element based on the anchor element's position.
   * Takes scroll position into account for non-fixed elements.
   */
  updatePosition() {
    if (!this.hasPositionedElementTarget || !this.hasAnchorTarget) {
      return;
    }

    const positionedElement = this.positionedElementTarget;

    if (this.positionStyleValue) {
      positionedElement.style.position = this.positionStyleValue;
    }

    const anchor = this.anchorTarget;
    const anchorRect = anchor.getBoundingClientRect();
    const elementRect = positionedElement.getBoundingClientRect();
    let limitX = window.innerWidth - elementRect.width;
    let limitY = window.innerHeight - elementRect.height;
    if (this.positionStyleValue !== "fixed") {
      // If the positioned element is not fixed, adjust limits to account for scroll position
      limitX += window.scrollX;
      limitY += window.scrollY;
    }
    const positionedElementComputedStyle =
      window.getComputedStyle(positionedElement);

    let [xOffset, yOffset] = this.calcOffsets(
      anchorRect.right,
      anchorRect.top,
      limitX, // Max x for element's left edge
      limitY, // Max y for element's top edge
      positionedElementComputedStyle.position !== "fixed",
    );

    positionedElement.style.left = `${xOffset}px`;
    positionedElement.style.top = `${yOffset}px`;
  }

  /**
   * Calculates the offsets for positioning an element based on initial coordinates, accounting for limits and scroll offsets.
   * @param initialX
   * @param initialY
   * @param limitX
   * @param limitY
   * @param scrollOffset - whether to include the current scroll position in the calculation
   * @returns {number[]} - an array ([x, y]) representing the calculated offsets for the left and top of the positioned element.
   */
  calcOffsets(initialX, initialY, limitX, limitY, scrollOffset = false) {
    let x = initialX;
    let y = initialY;

    if (scrollOffset) {
      x += window.scrollX;
      y += window.scrollY;
    }

    x = Math.min(x, limitX);
    y = Math.min(y, limitY);

    return [x, y];
  }

  positionedElementTargetConnected(elementTarget) {
    this.resizeObserver.observe(elementTarget);
    this.triggerUpdate();
  }

  positionedElementTargetDisconnected(elementTarget) {
    this.resizeObserver.unobserve(elementTarget);
  }

  anchorTargetConnected(anchorTarget) {
    this.resizeObserver.observe(anchorTarget);
  }

  anchorTargetDisconnected(anchorTarget) {
    this.resizeObserver.unobserve(anchorTarget);
  }
}
