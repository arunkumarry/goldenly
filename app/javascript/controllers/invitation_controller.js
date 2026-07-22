import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["profile", "deliveryChannel", "email", "phone", "emailInput", "phoneInput", "dialCode", "identifier"]

  connect() {
    this.updateDeliveryChannel()
  }

  updateContact() {
    const selectedOption = this.profileTarget.selectedOptions[0]
    if (selectedOption?.dataset.contact) this.phoneInputTarget.value = selectedOption.dataset.contact
  }

  updateDeliveryChannel() {
    const email = this.deliveryChannelTarget.value === "email"

    this.emailTarget.hidden = !email
    this.phoneTarget.hidden = email
    this.emailInputTarget.required = email
    this.phoneInputTarget.required = !email
    this.emailInputTarget.disabled = !email
    this.phoneInputTarget.disabled = email
    this.dialCodeTarget.disabled = email
    this.identifierTarget.value = ""
  }

  prepare(event) {
    const email = this.deliveryChannelTarget.value === "email"
    const contact = email ? this.emailInputTarget.value.trim() : this.phoneIdentifier()

    if (!contact) {
      event.preventDefault()
      return
    }

    this.identifierTarget.value = contact
  }

  phoneIdentifier() {
    const value = this.phoneInputTarget.value.trim()
    const digits = value.replace(/\D/g, "")
    if (!digits) return ""

    return value.startsWith("+") ? `+${digits}` : `${this.dialCodeTarget.value}${digits}`
  }
}
