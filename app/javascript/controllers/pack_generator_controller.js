import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "section"]

  connect() {
    this.element.addEventListener("turbo:submit-start", this._onSubmitStart)
    this.element.addEventListener("turbo:submit-end", this._onSubmitEnd)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this._onSubmitStart)
    this.element.removeEventListener("turbo:submit-end", this._onSubmitEnd)
  }

  cancel() {
    if (this._submission) {
      this._submission.stop()
      this._submission = null
    }
    this._resetUI()
  }

  _onSubmitStart = (event) => {
    this._submission = event.detail.formSubmission
    this.loadingTarget.classList.remove("d-none")
    this.sectionTarget.classList.add("d-none")
  }

  _onSubmitEnd = () => {
    this._submission = null
    this._resetUI()
  }

  _resetUI() {
    this.loadingTarget.classList.add("d-none")
    this.sectionTarget.classList.remove("d-none")
  }
}
