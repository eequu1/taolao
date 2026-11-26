import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String, url: String }

  connect() {
    console.log("connected!")
  }

  play(event) {
    event.preventDefault()
    console.log("play button clicked!", this.textValue, this.urlValue)

    // Download the audio only once; later clicks reuse it.
    this.audioData ||= this.fetchAudio()

    this.audioData
      .then(arrayBuffer => {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)()
        // decodeAudioData empties the buffer it gets, so give it a copy.
        return audioCtx.decodeAudioData(arrayBuffer.slice(0)).then(audioBuffer => {
          const source = audioCtx.createBufferSource()
          source.buffer = audioBuffer
          source.connect(audioCtx.destination)
          source.onended = () => audioCtx.close()
          source.start(0)
        })
      })
      .catch(error => {
        this.audioData = null // let the next click try again
        console.error("TTS Error:", error)
      })
  }

  fetchAudio() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    return fetch(this.urlValue, {
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
  }
}
