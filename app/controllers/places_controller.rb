class PlacesController < ApplicationController
  def index
    @selected_categories = Array(params[:category]).map(&:to_s) & Place::CATEGORIES.keys
    @places = Place.where.not(lat: nil, long: nil)
    @places = @places.where(category: @selected_categories) if @selected_categories.any?

    # A place query wins; otherwise fall back to the user location the Stimulus controller put in the params.
    coords = search_coordinates
    if coords
      @center = { lat: coords[0], lng: coords[1] }
      @places = @places.near(coords, 2, units: :km)
      flash.now[:notice] = "No places found near #{params[:query]}" if params[:query].present? && @places.empty?
    elsif params[:query].present?
      @center = { lat: coords[0], lng: coords[1] }
      @places = @places.near(coords, 2, units: :km)
      flash.now[:alert] = "Couldn't find \"#{params[:query]}\""
    end

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
      coordinate = Geocoder.search(params[:query]).first&.coordinates
      [params[:user_lat].to_f, params[:user_lng].to_f] unless coordinate.empty? || coordinate.nil?

    elsif params[:user_lat].present? && params[:user_lng].present?
      [params[:user_lat].to_f, params[:user_lng].to_f]
    end
  end
end
