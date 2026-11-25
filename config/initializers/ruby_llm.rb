RubyLLM.configure do |config|
  # The team keeps the OpenAI key in API_KEY; OPENAI_API_KEY wins if it's ever renamed.
  # Note: config/initializers/geocoder.rb also reads API_KEY (as a Google key) but makes
  # no API calls today. Don't enable automatic geocoding until the keys are separated.
  #
  # Tests never get the real key: a test that forgets to stub a reply fails instead of
  # calling (and paying for) OpenAI.
  config.openai_api_key = if Rails.env.test?
                            "test-key-not-used"
                          else
                            ENV["OPENAI_API_KEY"].presence || ENV.fetch("API_KEY", nil)
                          end
  config.default_model = "gpt-6.1-sol"
end
