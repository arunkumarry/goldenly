import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "current", "manual", "latitude", "longitude", "label", "error"]

  sourceChanged() {
    const source = this.selectedSource
    this.currentTarget.hidden = source !== "current_location"
    this.manualTarget.hidden = source !== "manual_location"
    this.errorTarget.textContent = ""
  }

  useCurrentLocation() {
    this.errorTarget.textContent = ""
    if (!navigator.geolocation) return this.showError("This browser cannot provide your location. Choose a saved or another address instead.")

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        this.latitudeTarget.value = coords.latitude
        this.longitudeTarget.value = coords.longitude
        this.labelTarget.value = "My current device location"
        this.currentTarget.querySelector("p").textContent = "Current location is ready for this search."
      },
      () => this.showError("Location permission was not granted. Choose a saved or another address instead."),
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 60_000 }
    )
  }

  get selectedSource() {
    return this.sourceTargets.find((input) => input.checked)?.value || "saved_address"
  }

  showError(message) {
    this.errorTarget.textContent = message
  }
}
