# frozen_string_literal: true

module Weather
  # Handles HTTP communication with WeatherAPI.com
  # Wraps HTTParty to provide a clean interface with proper error handling
  class WeatherApiClient
    include HTTParty

    base_uri ENV.fetch('WEATHER_API_BASE_URL', 'https://api.weatherapi.com/v1')
    default_timeout 10

    def fetch_current_weather(latitude, longitude)
      query_string = "#{latitude},#{longitude}"
      
      response = self.class.get('/current.json', {
        query: {
          key: api_key,
          q: query_string,
          aqi: 'no'
        },
        headers: default_headers
      })

      handle_response(response)
    end

    def fetch_forecast(latitude, longitude, days: 3)
      query_string = "#{latitude},#{longitude}"
      
      response = self.class.get('/forecast.json', {
        query: {
          key: api_key,
          q: query_string,
          days: days,
          aqi: 'no',
          alerts: 'no'
        },
        headers: default_headers
      })

      handle_response(response)
    end

    private

    def api_key
      key = ENV['WEATHER_API_KEY']
      
      if key.blank?
        raise WeatherApiError, 'Weather API key not configured. Please set WEATHER_API_KEY environment variable.'
      end
      
      key
    end

    def default_headers
      {
        'Content-Type' => 'application/json',
        'User-Agent' => 'WeatherForecastApp/1.0'
      }
    end

    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      when 400
        error_message = extract_error_message(response)
        raise WeatherApiError, "Bad request: #{error_message}"
      when 401
        raise WeatherApiError, 'Invalid API key'
      when 403
        raise WeatherApiError, 'API key quota exceeded or disabled'
      when 404
        raise WeatherApiError, 'Location not found'
      when 500..599
        raise WeatherApiError, 'Weather service is currently unavailable'
      else
        raise WeatherApiError, "Unexpected response code: #{response.code}"
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse weather API response: #{e.message}")
      raise WeatherApiError, 'Invalid response from weather service'
    end

    def extract_error_message(response)
      if response.parsed_response.is_a?(Hash)
        response.parsed_response.dig('error', 'message') || 'Unknown error'
      else
        'Unknown error'
      end
    end
  end

  class WeatherApiError < StandardError; end
end

