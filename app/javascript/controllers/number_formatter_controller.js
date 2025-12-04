import { Controller } from "@hotwired/stimulus"
import { formatNumeral } from "cleave-zen"

// Connects to data-controller="number-formatter"
export default class extends Controller {
  format(event) {
    const value = event.target.value
    event.target.value = formatNumeral(value, {
      numeralThousandsGroupStyle: 'thousand',
      numeralDecimalScale: 0
    })
  }
}
