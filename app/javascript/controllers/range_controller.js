import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="range"
export default class extends Controller {
  static targets = ["number", "display"];

  connect() {
    this.update();
  }

  update() {
    if (!this.hasNumberTarget || !this.hasDisplayTarget) return;

    const value = Number(this.numberTarget.value);
    this.displayTarget.textContent = value.toLocaleString();
  }
}
