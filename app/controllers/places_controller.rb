class PlacesController < ApplicationController
  def index
    @places = Place.where.not(lat: nil, long: nil)

    if params[:user_lat].present? && params[:user_lng].present?
      # Ép kiểu .to_f cho tọa độ
      @places = @places.near([params[:user_lat].to_f, params[:user_lng].to_f], 5, units: :km)
    end

    @markers = @places.map do |place|
      {
        lat: place.lat,
        lng: place.long,
        info_window_html: render_to_string(partial: "places/map_box", locals: { place: place })
      }
    end
  end

  def show
  end

  def create
  end
end
