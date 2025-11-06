# frozen_string_literal: true

module Geocoding
  # Converts addresses to coordinates and extracts location information
  # Uses caching to minimize API calls (1 hour cache)
  class GeocodingService
    class GeocodingError < StandardError; end

    def geocode_address(address)
      validate_address!(address)

      cache_key = generate_cache_key(address)
      
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        perform_geocoding(address)
      end
    rescue Geocoder::Error => e
      Rails.logger.error("Geocoder error for '#{address}': #{e.message}")
      raise GeocodingError, "Failed to geocode address: #{e.message}"
    end

    private

    def validate_address!(address)
      raise GeocodingError, 'Address cannot be blank' if address.blank?
    end

    def generate_cache_key(address)
      normalized_address = address.strip.downcase
      "geocoding:#{Digest::MD5.hexdigest(normalized_address)}"
    end

    def perform_geocoding(address)
      results = Geocoder.search(address)
      
      if results.empty?
        raise GeocodingError, 'No location found for the given address'
      end

      result = results.first
      extract_location_data(result)
    end

    def extract_location_data(result)
      {
        latitude: result.latitude,
        longitude: result.longitude,
        zip_code: extract_zip_code(result),
        formatted_address: result.address,
        city: result.city,
        state: result.state,
        country: result.country
      }
    end

    # Different geocoding services store zip codes in different fields
    def extract_zip_code(result)
      result.postal_code || 
        result.zipcode || 
        result.data.dig('address', 'postcode') ||
        result.data.dig('address', 'zip')
    end
  end
end

