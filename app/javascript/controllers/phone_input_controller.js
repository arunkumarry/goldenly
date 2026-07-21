import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "phone"]

  sync() {
    const value = this.phoneTarget.value.trim()
    if (value.startsWith("+") || !value.match(/\d/)) return

    this.phoneTarget.value = `${this.codeTarget.value}${value.replace(/\D/g, "")}`
  }
}
