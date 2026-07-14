import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "button", "message"]
  static values = { seconds: { type: Number, default: 300 } }

  connect() {
    this.remaining = this.secondsValue
    this.running = false
    this.render()
  }

  disconnect() {
    this.stopTimer()
  }

  toggle() {
    this.running ? this.pause() : this.start()
  }

  start() {
    if (this.remaining <= 0) this.remaining = this.secondsValue
    this.running = true
    this.buttonTarget.textContent = "一時停止"
    this.messageTarget.textContent = "今はこの5分だけに集中しましょう。"
    this.interval = window.setInterval(() => this.tick(), 1000)
  }

  pause() {
    this.stopTimer()
    this.buttonTarget.textContent = "再開"
    this.messageTarget.textContent = "止まっても大丈夫。いつでも再開できます。"
  }

  reset() {
    this.stopTimer()
    this.remaining = this.secondsValue
    this.buttonTarget.textContent = "スタート"
    this.messageTarget.textContent = "深呼吸して、最初の一歩から。"
    this.render()
  }

  tick() {
    this.remaining -= 1
    this.render()
    if (this.remaining <= 0) {
      this.stopTimer()
      this.buttonTarget.textContent = "もう5分"
      this.messageTarget.textContent = "5分できました。着手できたことが成果です！"
    }
  }

  stopTimer() {
    if (this.interval) window.clearInterval(this.interval)
    this.interval = null
    this.running = false
  }

  render() {
    const minutes = Math.floor(this.remaining / 60)
    const seconds = String(this.remaining % 60).padStart(2, "0")
    this.displayTarget.textContent = `${minutes}:${seconds}`
  }
}
