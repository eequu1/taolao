class PlacesController < ApplicationController
  def index
    @places = Place.new
  end

  def show
    @place = Place.find(params[:id])
  end

  def create
  end
end
