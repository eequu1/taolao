class PlacesController < ApplicationController
  def index
    @places = Place.where.not(lat: nil, long: nil)
    coords = search_coordinates
    if params[:category].present? && params[:category].reject(&:blank?).any? && coords
      @places = @places.where(category: params[:category]).near(coords, 2, units: :km)
      @center = { lat: coords[0], lng: coords[1] }
      # raise
    elsif coords
      @center = { lat: coords[0], lng: coords[1] }
      @places = @places.near(coords, 2, units: :km)
    elsif params[:query].present?
      flash.now[:alert] = "Couldn't find \"#{params[:query]}\""
      @center = { lat: coords[0], lng: coords[1] }
    end

    flash.now[:notice] = "No places found near #{params[:query]}" if params[:query].present? && coords && @places.empty?

    @markers = @places.map do |place|
      {
        lat: place.lat,
        lng: place.long,
        info_window_html: render_to_string(partial: "places/place_box", locals: { place: place })
      }
    end
  end

  def show
    @place = Place.find(params[:id])
  end

  def create
  end

  def speak
    text = params[:text].to_s
    # Gemini takes 3-4s per request, so reuse audio we already generated for the same text.
    # Bump "v1" if the voice or the audio processing changes, so old audio isn't reused.
    @audio_binary = Rails.cache.fetch(["tts", "v1", Digest::SHA256.hexdigest(text)], expires_in: 30.days) do
      GeminiTtsService.synthesize(text)
    end
    send_data @audio_binary, type: "audio/wav", disposition: "inline"
  end

  private

  def search_coordinates
    if params[:query].present?
      Geocoder.search(params[:query]).first&.coordinates
    elsif params[:user_lat].present? && params[:user_lng].present?
      [params[:user_lat].to_f, params[:user_lng].to_f]
    end
  end
end
