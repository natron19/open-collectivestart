import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const params = new URLSearchParams(window.location.search)
    const active = params.get("tab")
    if (active) {
      const btn = this.element.querySelector(`[data-tab-url-sync-key-param="${active}"]`)
      if (btn) window.bootstrap.Tab.getOrCreateInstance(btn).show()
    }

    this.element.addEventListener("show.bs.tab", (event) => {
      const key = event.target.dataset.tabUrlSyncKeyParam
      if (!key) return
      const url = new URL(window.location)
      url.searchParams.set("tab", key)
      history.replaceState({}, "", url)
    })
  }
}
