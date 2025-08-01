import Popover from "@stimulus-components/popover";

// Connects to data-controller="stimulus-popover"
export default class extends Popover {
  initialize() {
    super.initialize();
    this.outsideClickHandler = this.handleOutsideClick.bind(this);
    this.open = false;
  }

  connect() {
    super.connect();
  }

  disconnect() {
    super.connect();
    this.removeOutsideClickListener();
  }

  async show(event) {
    if (this.open) return;
    await super.show(event);

    // Wait a bit to ensure the popover is rendered before adding the click listener
    setTimeout(() => {
      document.addEventListener("click", this.outsideClickHandler);
    }, 10);
    this.open = true;
  }

  hide() {
    if (!this.open) return;
    if (this.hasCardTarget) {
      // The last card target is the one in the popover
      this.cardTarget.remove();
    }
    this.removeOutsideClickListener();
    this.open = false;
  }

  handleOutsideClick(event) {
    // Get the popover element
    const popoverCard = this.hasCardTarget ? this.cardTarget : null;
    if (!popoverCard) return;

    // Get the trigger element that opens the popover
    const triggerElement = this.element.querySelector(
      '[data-action*="stimulus-popover#show"]',
    );

    // Check if click is outside both the popover and trigger
    const isClickOutsidePopover = !popoverCard.contains(event.target);
    const isClickOutsideTrigger =
      !triggerElement || !triggerElement.contains(event.target);

    if (isClickOutsidePopover && isClickOutsideTrigger) {
      this.hide();
    }
  }

  removeOutsideClickListener() {
    document.removeEventListener("click", this.outsideClickHandler);
  }
}
