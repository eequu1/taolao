class PlacesController < ApplicationController
  def index
    @places = Place.where.not(lat: nil, long: nil)
    coords = search_coordinates
    if coords
      @center = { lat: coords[0], lng: coords[1] }
      @places = @places.near(coords, 2, units: :km)
    elsif params[:query].present?
      flash.now[:alert] = "Couldn't find \"#{params[:query]}\""
    end
    flash.now[:notice] = "No places found near #{params[:query]}" if params[:query].present? && coords && @places.empty?
    @markers = @places.map do |place|
      {
        lat: place.lat,
        lng: place.long,
        info_window_html: render_to_string(partial: "places/map_box", locals: { place: place })
      }
    end
  end

  # redirect_to places_path, notice: "No places found" if @places.empty?

  # def index
  #   if params[:query]
  #     @places = Place.where.not(lat: nil, long: nil)
  #     @places = @places.near(params[:query], 5, units: :km)
  #   else
  #     @places = Place.where.not(lat: nil, long: nil)
  #     if params[:user_lat].present? && params[:user_lng].present?
  #       @places = @places.near([params[:user_lat].to_f, params[:user_lng].to_f], 5, units: :km)
  #     end
  #   end

  #   @markers = @places.map do |place|
  #     {
  #       lat: place.lat,
  #       lng: place.long,
  #       info_window_html: render_to_string(partial: "places/map_box", locals: { place: place })
  #     }
  #   end
  # end

  def show
    @place = Place.find(params[:id])
  end

  def create
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
