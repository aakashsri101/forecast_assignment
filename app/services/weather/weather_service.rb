# frozen_string_literal: true

module Weather
  # Fetches weather data and transforms it into application format
  # Separates business logic from API communication
  class WeatherService
    def initialize(api_client: WeatherApiClient.new)
      @api_client = api_client
    end

    def get_weather_for_location(latitude, longitude, zip_code)
      forecast_data = @api_client.fetch_forecast(latitude, longitude, days: 3)
      
      transform_weather_data(forecast_data, zip_code)
    rescue StandardError => e
      Rails.logger.error("Weather service error: #{e.message}")
      raise
    end

    private

    def transform_weather_data(api_data, zip_code)
      current = api_data['current']
      location = api_data['location']
      forecast = api_data['forecast']

      {
        zip_code: zip_code,
        location: {
          name: location['name'],
          region: location['region'],
          country: location['country'],
          latitude: location['lat'],
          longitude: location['lon'],
          timezone: location['tz_id'],
          localtime: location['localtime']
        },
        current: {
          temperature_f: current['temp_f'],
          temperature_c: current['temp_c'],
          condition: current['condition']['text'],
          condition_icon: current['condition']['icon'],
          humidity: current['humidity'],
          wind_mph: current['wind_mph'],
          wind_kph: current['wind_kph'],
          wind_direction: current['wind_dir'],
          pressure_mb: current['pressure_mb'],
          pressure_in: current['pressure_in'],
          precip_mm: current['precip_mm'],
          precip_in: current['precip_in'],
          feels_like_f: current['feelslike_f'],
          feels_like_c: current['feelslike_c'],
          uv_index: current['uv'],
          last_updated: current['last_updated']
        },
        forecast: transform_forecast_data(forecast),
        retrieved_at: Time.current
      }
    end

    def transform_forecast_data(forecast)
      return [] unless forecast && forecast['forecastday']

      forecast['forecastday'].map do |day|
        {
          date: day['date'],
          date_epoch: day['date_epoch'],
          day: {
            max_temp_f: day['day']['maxtemp_f'],
            max_temp_c: day['day']['maxtemp_c'],
            min_temp_f: day['day']['mintemp_f'],
            min_temp_c: day['day']['mintemp_c'],
            avg_temp_f: day['day']['avgtemp_f'],
            avg_temp_c: day['day']['avgtemp_c'],
            condition: day['day']['condition']['text'],
            condition_icon: day['day']['condition']['icon'],
            max_wind_mph: day['day']['maxwind_mph'],
            max_wind_kph: day['day']['maxwind_kph'],
            total_precip_mm: day['day']['totalprecip_mm'],
            total_precip_in: day['day']['totalprecip_in'],
            avg_humidity: day['day']['avghumidity'],
            chance_of_rain: day['day']['daily_chance_of_rain'],
            chance_of_snow: day['day']['daily_chance_of_snow']
          },
          astro: {
            sunrise: day['astro']['sunrise'],
            sunset: day['astro']['sunset'],
            moonrise: day['astro']['moonrise'],
            moonset: day['astro']['moonset'],
            moon_phase: day['astro']['moon_phase']
          }
        }
      end
    end
  end
end

