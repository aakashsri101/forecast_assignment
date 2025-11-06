# frozen_string_literal: true

# Coordinates geocoding, weather fetching, and caching services
# Provides a single entry point for weather forecast operations
class WeatherForecastFacade
  class << self
    def get_forecast(address)
      location_info = geocoding_service.geocode_address(address)
      
      cache_result = cache_service.fetch_or_store(location_info[:zip_code]) do
        weather_service.get_weather_for_location(
          location_info[:latitude],
          location_info[:longitude],
          location_info[:zip_code]
        )
      end
      {
        forecast: cache_result[:forecast],
        location: location_info,
        from_cache: cache_result[:from_cache],
        cached_at: cache_result[:cached_at],
        expires_at: cache_result[:expires_at]
      }
    end

    def clear_cache(zip_code)
      cache_service.clear_cache_for_zip(zip_code)
    end

    private

    def geocoding_service
      @geocoding_service ||= Geocoding::GeocodingService.new
    end

    def weather_service
      @weather_service ||= Weather::WeatherService.new
    end

    def cache_service
      @cache_service ||= Caching::ForecastCacheService.new
    end

    # Resets service instances (useful for testing)
    def reset_services!
      @geocoding_service = nil
      @weather_service = nil
      @cache_service = nil
    end
  end
end

