import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "coordinatorFields"]

  connect() { this.toggle() }

  toggle() {
    const choice = this.hasChoiceTarget ? this.choiceTarget.value : this.element.querySelector("input[name='setup_for']:checked")?.value
    this.coordinatorFieldsTargets.forEach((element) => { element.hidden = choice === "self" })
  }
}
