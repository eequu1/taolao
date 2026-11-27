class PlacesController < ApplicationController
  def index
    @selected_categories = Array(params[:category]).map(&:to_s) & Place::CATEGORIES.keys
    @places = Place.where.not(lat: nil, long: nil)
    @places = @places.where(category: @selected_categories) if @selected_categories.any?

    coords = search_coordinates
    if coords
      @center = { lat: coords[0], lng: coords[1] }
      @places = @places.near(coords, 2, units: :km)
      flash.now[:notice] = "No places found near #{params[:query]}" if @places.empty? && params[:query].present?
    end
    flash.now[:alert] = "Couldn't find \"#{params[:query]}\"" if @query_not_found

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
    # First view: phrases are generated in the background and pushed to the page when ready
    @place.generate_phrases_later
    @generating_phrases = @place.phrases_generating?
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

  # A place query that geocodes wins. A query that doesn't geocode is reported and ignored, so the map stays
  # on the user's location (user_lat/user_lng, set by the Stimulus controller and kept by the search form).
  def search_coordinates
    if params[:query].present?
      query_coords = Geocoder.search(params[:query]).first&.coordinates
      return query_coords if query_coords

      @query_not_found = true
    end
    user_coordinates
  end

  def user_coordinates
    return unless params[:user_lat].present? && params[:user_lng].present?

    [params[:user_lat].to_f, params[:user_lng].to_f]
  end
end
