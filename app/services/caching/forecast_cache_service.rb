# frozen_string_literal: true

module Caching
  # Manages 30-minute caching of weather forecasts by zip code
  # Uses Redis for distributed caching across multiple servers
  class ForecastCacheService
    CACHE_EXPIRATION = ENV.fetch('CACHE_EXPIRATION_MINUTES', 30).to_i.minutes

    def fetch_or_store(zip_code, &block)
      validate_zip_code!(zip_code)

      cache_key = generate_cache_key(zip_code)
      cached_result = fetch_from_cache(cache_key)

      if cached_result
        Rails.logger.info("Cache HIT for zip code: #{zip_code}")
        return build_result_with_metadata(cached_result, from_cache: true)
      end

      Rails.logger.info("Cache MISS for zip code: #{zip_code}")
      fresh_data = block.call
      store_in_cache(cache_key, fresh_data)
      
      build_result_with_metadata(fresh_data, from_cache: false)
    end

    def clear_cache_for_zip(zip_code)
      cache_key = generate_cache_key(zip_code)
      Rails.cache.delete(cache_key)
      Rails.logger.info("Cache cleared for zip code: #{zip_code}")
      true
    end

    def clear_all_caches
      Rails.cache.delete_matched("#{cache_namespace}:*")
      Rails.logger.info('All forecast caches cleared')
      true
    end

    private

    def validate_zip_code!(zip_code)
      raise ArgumentError, 'Zip code cannot be blank' if zip_code.blank?
    end

    def generate_cache_key(zip_code)
      normalized_zip = zip_code.to_s.strip.downcase
      "#{cache_namespace}:#{normalized_zip}"
    end

    def cache_namespace
      'weather_forecast'
    end

    def fetch_from_cache(cache_key)
      Rails.cache.read(cache_key)
    rescue StandardError => e
      Rails.logger.error("Error reading from cache: #{e.message}")
      nil
    end

    def store_in_cache(cache_key, data)
      cache_entry = {
        data: data,
        cached_at: Time.current
      }

      Rails.cache.write(cache_key, cache_entry, expires_in: CACHE_EXPIRATION)
      true
    rescue StandardError => e
      Rails.logger.error("Error writing to cache: #{e.message}")
      false
    end

    def build_result_with_metadata(cached_entry, from_cache:)
      if from_cache
        {
          forecast: cached_entry[:data],
          from_cache: true,
          cached_at: cached_entry[:cached_at],
          expires_at: cached_entry[:cached_at] + CACHE_EXPIRATION
        }
      else
        {
          forecast: cached_entry,
          from_cache: false,
          cached_at: Time.current,
          expires_at: Time.current + CACHE_EXPIRATION
        }
      end
    end
  end
end

