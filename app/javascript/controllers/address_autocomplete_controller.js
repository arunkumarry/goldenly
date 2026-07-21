import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "city", "location", "region", "country", "countryCode", "postalCode", "placeId", "latitude", "longitude"]

  connect() {
    this.sessionToken = crypto.randomUUID().replaceAll("-", "")
    this.timer = null
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  search() {
    clearTimeout(this.timer)
    const input = this.inputTarget.value.trim()
    if (input.length < 3) return this.clearResults()

    this.timer = setTimeout(() => this.fetchSuggestions(input), 300)
  }

  async fetchSuggestions(input) {
    try {
      const response = await fetch(`/places/autocomplete?input=${encodeURIComponent(input)}&session_token=${this.sessionToken}`, { headers: { Accept: "application/json" } })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Address suggestions are unavailable.")
      this.renderSuggestions(payload.suggestions || [])
    } catch (error) {
      this.resultsTarget.replaceChildren(this.message(error.message))
    }
  }

  async select(event) {
    const { placeId } = event.currentTarget.dataset
    this.clearResults()
    try {
      const response = await fetch(`/places/${encodeURIComponent(placeId)}?session_token=${this.sessionToken}`, { headers: { Accept: "application/json" } })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Address details are unavailable.")
      this.assign(payload.place)
    } catch (error) {
      this.resultsTarget.replaceChildren(this.message(error.message))
    }
  }

  renderSuggestions(suggestions) {
    this.clearResults()
    if (!suggestions.length) return

    const list = document.createElement("div")
    list.className = "address-suggestions"
    suggestions.forEach((suggestion) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "address-suggestion"
      button.dataset.action = "address-autocomplete#select"
      button.dataset.placeId = suggestion.place_id
      button.textContent = suggestion.text
      list.append(button)
    })
    const attribution = document.createElement("small")
    attribution.className = "google-attribution"
    attribution.textContent = "Powered by Google"
    list.append(attribution)
    this.resultsTarget.append(list)
  }

  assign(place) {
    this.inputTarget.value = place.address || ""
    this.set("city", place.city)
    this.set("location", place.city)
    this.set("region", place.region)
    this.set("country", place.country)
    this.set("countryCode", place.country_code)
    this.set("postalCode", place.postal_code)
    this.set("placeId", place.place_id)
    this.set("latitude", place.latitude)
    this.set("longitude", place.longitude)
  }

  set(target, value) {
    if (this[`has${target[0].toUpperCase()}${target.slice(1)}Target`]) this[`${target}Target`].value = value || ""
  }

  clearResults() {
    this.resultsTarget.replaceChildren()
  }

  message(text) {
    const message = document.createElement("p")
    message.className = "address-message"
    message.textContent = text
    return message
  }
}
