import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return this.revealAll()

    this.observer = new IntersectionObserver((entries) => {
      entries.filter((entry) => entry.isIntersecting).forEach((entry) => {
        const item = entry.target
        item.classList.add("is-visible")
        this.observer.unobserve(item)
      })
    }, { threshold: 0.2 })

    this.itemTargets.forEach((item, index) => {
      item.style.setProperty("--reveal-delay", `${index * 130}ms`)
      this.observer.observe(item)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  revealAll() {
    this.itemTargets.forEach((item) => item.classList.add("is-visible"))
  }
end
