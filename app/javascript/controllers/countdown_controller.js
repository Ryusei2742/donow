import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "message", "running", "outcome"]
  static values = { endAt: String }

  connect() {
    if (!this.hasEndAtValue || !this.hasDisplayTarget) return

    this.handleVisibilityChange = () => this.render()
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
    this.render()
    this.interval = window.setInterval(() => this.render(), 250)
  }

  disconnect() {
    if (this.interval) window.clearInterval(this.interval)
    if (this.handleVisibilityChange) {
      document.removeEventListener("visibilitychange", this.handleVisibilityChange)
    }
  }

  render() {
    const endAt = Date.parse(this.endAtValue)
    if (Number.isNaN(endAt)) return

    const remaining = Math.max(0, Math.ceil((endAt - Date.now()) / 1000))
    const minutes = Math.floor(remaining / 60)
    const seconds = String(remaining % 60).padStart(2, "0")
    this.displayTarget.textContent = `${minutes}:${seconds}`

    if (remaining === 0) this.expire()
  }

  expire() {
    if (this.interval) window.clearInterval(this.interval)
    this.interval = null
    if (this.hasMessageTarget) this.messageTarget.textContent = "時間になりました。次の行動を選びましょう。"
    if (this.hasRunningTarget) this.runningTarget.hidden = true
    if (this.hasOutcomeTarget) this.outcomeTarget.hidden = false
  }
}
