import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "count"]

  connect() {
    this.update()
  }

  update() {
    this.countTarget.textContent = this.fieldTarget.value.length
  }
}
