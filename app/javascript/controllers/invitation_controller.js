import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["profile", "contact", "dialCode"]

  updateContact() {
    const selectedOption = this.profileTarget.selectedOptions[0]
    if (selectedOption?.dataset.contact) this.contactTarget.value = selectedOption.dataset.contact
  }

  addDialCode() {
    const value = this.contactTarget.value.trim()
    return if value.startsWith("+") || !value.match?(/\d/)

    this.contactTarget.value = `${this.dialCodeTarget.value}${value.replace(/\D/g, "")}`
  }
}
