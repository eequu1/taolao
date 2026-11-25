import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String, url: String }

  connect() {
    console.log("connected!")
  }

  play(event) {
    event.preventDefault()
    console.log("play button clicked!", this.textValue, this.urlValue)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ text: this.textValue })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`server returned status ${response.status}`)
      }
      return response.arrayBuffer()
    })
    .then(arrayBuffer => {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)()
      return audioCtx.decodeAudioData(arrayBuffer)
    })
    .then(audioBuffer => {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)()
      const source = audioCtx.createBufferSource()
      source.buffer = audioBuffer
      source.connect(audioCtx.destination)
      source.start(0)
    })
    .catch(error => console.error("TTS Error:", error))
  }
}
