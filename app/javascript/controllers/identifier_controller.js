import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "phone", "emailInput", "phoneInput", "dialCode", "identifier", "emailButton", "phoneButton"]

  connect() { this.selectEmail() }

  selectEmail() { this.select("email") }
  selectPhone() { this.select("phone") }

  prepare(event) {
    const identifier = this.phoneTarget.hidden
      ? this.emailInputTarget.value.trim()
      : `${this.dialCodeTarget.value}${this.phoneInputTarget.value.replace(/\D/g, "")}`
    if (!identifier) return event.preventDefault()

    this.identifierTarget.value = identifier
  }

  select(type) {
    const email = type === "email"
    this.emailTarget.hidden = !email
    this.phoneTarget.hidden = email
    this.emailInputTarget.required = email
    this.phoneInputTarget.required = !email
    this.emailButtonTarget.classList.toggle("identifier-toggle-active", email)
    this.phoneButtonTarget.classList.toggle("identifier-toggle-active", !email)
  }
}
