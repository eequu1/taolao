require "net/http"
require "uri"
require "json"
require "base64"

class GeminiTtsService
  def self.synthesize(text)
    # Correct environment variable name and dedicated TTS model endpoint
    api_key = ENV.fetch("GEMINI_API_KEY", nil)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash-tts:generateContent?key=#{api_key}")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      contents: [{
        parts: [{ text: text }]
      }],
      generationConfig: {
        responseModalities: ["AUDIO"],
        speechConfig: {
          voiceConfig: {
            prebuiltVoiceConfig: {
              voiceName: "Callirrhoe"
            }
          }
        }
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    raise "Gemini API HTTP Error #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    json_response = JSON.parse(response.body)

    # Safely extract the audio binary payload returned by Gemini
    base64_audio = json_response.dig("candidates", 0, "content", "parts", 0, "inlineData", "data")
    base64_audio ||= json_response.dig("candidates", 0, "content", "parts", 0, "inline_data", "data")

    raise "Gemini API did not return audio data: #{json_response}" unless base64_audio

    raw_pcm = Base64.decode64(base64_audio)
    generate_wav_header(raw_pcm)
  end

  private

  def self.generate_wav_header(pcm_data)
    sample_rate = 24_000
    bits_per_sample = 16
    channels = 1
    byte_rate = sample_rate * channels * bits_per_sample / 8
    block_align = channels * bits_per_sample / 8
    data_size = pcm_data.bytesize
    chunk_size = 36 + data_size

    header = [
      "RIFF",
      chunk_size,
      "WAVE",
      "fmt ",
      16,
      1,
      channels,
      sample_rate,
      byte_rate,
      block_align,
      bits_per_sample,
      "data",
      data_size
    ].pack("A4V A4 A4 V v v V V v v A4V")

    header + pcm_data
  end
end
