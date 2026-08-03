import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, type: String, placeId: String }

  async follow(event) {
    event.preventDefault()
    const destination = this.element.href
    const opensNewWindow = this.element.target === "_blank"
    try {
      await fetch(this.urlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "", Accept: "application/json" },
        body: JSON.stringify({ google_place_id: this.placeIdValue, action_type: this.typeValue })
      })
    } finally {
      if (opensNewWindow) window.open(destination, "_blank", "noopener")
      else window.location.assign(destination)
    }
  }
}
