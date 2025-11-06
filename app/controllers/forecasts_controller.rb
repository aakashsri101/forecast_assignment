# frozen_string_literal: true

# Handles weather forecast requests
# Uses the Facade pattern to coordinate between geocoding, weather, and caching services
class ForecastsController < ApplicationController
  def index
    # Render the search form
  end

  def create
    address = params[:address]

    if address.blank?
      flash.now[:error] = 'Please enter an address to get the forecast.'
      render :index and return
    end

    begin
      result = WeatherForecastFacade.get_forecast(address)

      @forecast_data = result[:forecast]
      @location_info = result[:location]
      @from_cache = result[:from_cache]
      @cached_at = result[:cached_at]

      render :show
    rescue Geocoding::GeocodingService::GeocodingError => e
      Rails.logger.warn("Geocoding error for address '#{address}': #{e.message}")
      flash.now[:error] = "Unable to find location: #{e.message}"
      render :index
    rescue Weather::WeatherApiError => e
      Rails.logger.error("Weather API error: #{e.message}")
      flash.now[:error] = "Unable to retrieve weather data: #{e.message}"
      render :index
    rescue StandardError => e
      Rails.logger.error("Unexpected error in ForecastsController#create: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      flash.now[:error] = 'An unexpected error occurred. Please try again later.'
      render :index
    end
  end
end

