# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Weather::WeatherService do
  let(:api_client) { instance_double(Weather::WeatherApiClient) }
  let(:service) { described_class.new(api_client: api_client) }
  
  let(:latitude) { 37.3349 }
  let(:longitude) { -122.0090 }
  let(:zip_code) { '95014' }

  let(:api_response) do
    {
      'location' => {
        'name' => 'Cupertino',
        'region' => 'California',
        'country' => 'United States of America',
        'lat' => latitude,
        'lon' => longitude,
        'tz_id' => 'America/Los_Angeles',
        'localtime' => '2024-01-15 10:30'
      },
      'current' => {
        'temp_f' => 72.0,
        'temp_c' => 22.2,
        'condition' => {
          'text' => 'Partly cloudy',
          'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png'
        },
        'humidity' => 65,
        'wind_mph' => 8.1,
        'wind_kph' => 13.0,
        'wind_dir' => 'W',
        'pressure_mb' => 1015.0,
        'pressure_in' => 29.97,
        'precip_mm' => 0.0,
        'precip_in' => 0.0,
        'feelslike_f' => 70.0,
        'feelslike_c' => 21.1,
        'uv' => 5.0,
        'last_updated' => '2024-01-15 10:30'
      },
      'forecast' => {
        'forecastday' => [
          {
            'date' => '2024-01-15',
            'date_epoch' => 1705276800,
            'day' => {
              'maxtemp_f' => 75.0,
              'maxtemp_c' => 23.9,
              'mintemp_f' => 55.0,
              'mintemp_c' => 12.8,
              'avgtemp_f' => 65.0,
              'avgtemp_c' => 18.3,
              'condition' => {
                'text' => 'Sunny',
                'icon' => '//cdn.weatherapi.com/weather/64x64/day/113.png'
              },
              'maxwind_mph' => 10.0,
              'maxwind_kph' => 16.1,
              'totalprecip_mm' => 0.0,
              'totalprecip_in' => 0.0,
              'avghumidity' => 60.0,
              'daily_chance_of_rain' => 0,
              'daily_chance_of_snow' => 0
            },
            'astro' => {
              'sunrise' => '07:15 AM',
              'sunset' => '05:30 PM',
              'moonrise' => '08:45 PM',
              'moonset' => '09:30 AM',
              'moon_phase' => 'Waxing Crescent'
            }
          }
        ]
      }
    }
  end

  describe '#get_weather_for_location' do
    before do
      allow(api_client).to receive(:fetch_forecast).and_return(api_response)
    end

    it 'fetches and transforms weather data' do
      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result).to be_a(Hash)
      expect(result[:zip_code]).to eq(zip_code)
      expect(result[:location][:name]).to eq('Cupertino')
      expect(result[:current][:temperature_f]).to eq(72.0)
    end

    it 'includes location information' do
      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result[:location]).to include(
        name: 'Cupertino',
        region: 'California',
        country: 'United States of America',
        latitude: latitude,
        longitude: longitude,
        timezone: 'America/Los_Angeles'
      )
    end

    it 'includes current weather information' do
      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result[:current]).to include(
        temperature_f: 72.0,
        temperature_c: 22.2,
        condition: 'Partly cloudy',
        humidity: 65,
        wind_mph: 8.1
      )
    end

    it 'includes forecast information' do
      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result[:forecast]).to be_an(Array)
      expect(result[:forecast].length).to eq(1)
      
      forecast_day = result[:forecast].first
      expect(forecast_day[:date]).to eq('2024-01-15')
      expect(forecast_day[:day][:max_temp_f]).to eq(75.0)
      expect(forecast_day[:day][:min_temp_f]).to eq(55.0)
    end

    it 'includes astronomical data in forecast' do
      result = service.get_weather_for_location(latitude, longitude, zip_code)

      astro = result[:forecast].first[:astro]
      expect(astro).to include(
        sunrise: '07:15 AM',
        sunset: '05:30 PM',
        moon_phase: 'Waxing Crescent'
      )
    end

    it 'includes retrieved_at timestamp' do
      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result[:retrieved_at]).to be_a(Time)
      expect(result[:retrieved_at]).to be_within(1.second).of(Time.current)
    end

    context 'when API client raises an error' do
      before do
        allow(api_client).to receive(:fetch_forecast).and_raise(Weather::WeatherApiError, 'API error')
      end

      it 're-raises the error' do
        expect {
          service.get_weather_for_location(latitude, longitude, zip_code)
        }.to raise_error(Weather::WeatherApiError, 'API error')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        begin
          service.get_weather_for_location(latitude, longitude, zip_code)
        rescue Weather::WeatherApiError
          # Expected error
        end

        expect(Rails.logger).to have_received(:error).with(/Weather service error/)
      end
    end
  end

  describe 'data transformation' do
    before do
      allow(api_client).to receive(:fetch_forecast).and_return(api_response)
    end

    it 'handles multiple forecast days' do
      api_response['forecast']['forecastday'] << {
        'date' => '2024-01-16',
        'date_epoch' => 1705363200,
        'day' => api_response['forecast']['forecastday'][0]['day'],
        'astro' => api_response['forecast']['forecastday'][0]['astro']
      }

      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result[:forecast].length).to eq(2)
    end

    it 'handles missing forecast data gracefully' do
      api_response['forecast'] = nil

      result = service.get_weather_for_location(latitude, longitude, zip_code)

      expect(result[:forecast]).to eq([])
    end
  end
end

