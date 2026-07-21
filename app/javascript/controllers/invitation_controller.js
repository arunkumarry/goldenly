import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["profile", "contact"]

  updateContact() {
    const selectedOption = this.profileTarget.selectedOptions[0]
    if (selectedOption?.dataset.contact) this.contactTarget.value = selectedOption.dataset.contact
  }
}
