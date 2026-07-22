import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["service", "details", "credentialDetails", "serviceZone", "credentialType", "credentialIssuer"]
  static values = { clinicalServiceIds: Array }

  connect() {
    this.toggle()
  }

  toggle() {
    const selected = this.serviceTarget.value
    const hasService = selected.length > 0
    const needsCredential = this.clinicalServiceIdsValue.map(String).includes(selected)

    this.detailsTarget.hidden = !hasService
    this.credentialDetailsTarget.hidden = !needsCredential
    this.serviceZoneTarget.required = hasService
    this.credentialTypeTarget.required = needsCredential
    this.credentialIssuerTarget.required = needsCredential
  }
}
