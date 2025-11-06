# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Weather::WeatherApiClient do
  let(:client) { described_class.new }
  let(:latitude) { 37.3349 }
  let(:longitude) { -122.0090 }
  let(:api_key) { 'test_api_key_123' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('WEATHER_API_KEY').and_return(api_key)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('WEATHER_API_BASE_URL', anything).and_return('https://api.weatherapi.com/v1')
  end

  describe '#fetch_current_weather' do
    context 'with successful API response' do
      let(:successful_response) do
        {
          'location' => {
            'name' => 'Cupertino',
            'region' => 'California',
            'country' => 'United States'
          },
          'current' => {
            'temp_f' => 72.0,
            'temp_c' => 22.2,
            'condition' => {
              'text' => 'Partly cloudy',
              'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png'
            },
            'humidity' => 65,
            'wind_mph' => 8.1
          }
        }
      end

      before do
        stub_request(:get, %r{https://api.weatherapi.com/v1/current.json})
          .to_return(status: 200, body: successful_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns parsed weather data' do
        result = client.fetch_current_weather(latitude, longitude)

        expect(result).to be_a(Hash)
        expect(result['current']['temp_f']).to eq(72.0)
        expect(result['location']['name']).to eq('Cupertino')
      end
    end

    context 'with invalid API key' do
      before do
        stub_request(:get, %r{https://api.weatherapi.com/v1/current.json})
          .to_return(status: 401, body: '{"error": {"message": "Invalid API key"}}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises WeatherApiError' do
        expect {
          client.fetch_current_weather(latitude, longitude)
        }.to raise_error(Weather::WeatherApiError, 'Invalid API key')
      end
    end

    context 'with missing API key' do
      before do
        allow(ENV).to receive(:[]).with('WEATHER_API_KEY').and_return(nil)
      end

      it 'raises WeatherApiError' do
        expect {
          client.fetch_current_weather(latitude, longitude)
        }.to raise_error(Weather::WeatherApiError, /Weather API key not configured/)
      end
    end

    context 'with quota exceeded error' do
      before do
        stub_request(:get, %r{https://api.weatherapi.com/v1/current.json})
          .to_return(status: 403, body: '{"error": {"message": "Quota exceeded"}}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises WeatherApiError' do
        expect {
          client.fetch_current_weather(latitude, longitude)
        }.to raise_error(Weather::WeatherApiError, 'API key quota exceeded or disabled')
      end
    end

    context 'with location not found error' do
      before do
        stub_request(:get, %r{https://api.weatherapi.com/v1/current.json})
          .to_return(status: 404, body: '{"error": {"message": "Location not found"}}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises WeatherApiError' do
        expect {
          client.fetch_current_weather(latitude, longitude)
        }.to raise_error(Weather::WeatherApiError, 'Location not found')
      end
    end

    context 'with server error' do
      before do
        stub_request(:get, %r{https://api.weatherapi.com/v1/current.json})
          .to_return(status: 500, body: 'Internal Server Error', headers: {})
      end

      it 'raises WeatherApiError' do
        expect {
          client.fetch_current_weather(latitude, longitude)
        }.to raise_error(Weather::WeatherApiError, 'Weather service is currently unavailable')
      end
    end
  end

  describe '#fetch_forecast' do
    context 'with successful API response' do
      let(:forecast_response) do
        {
          'location' => { 'name' => 'Cupertino' },
          'current' => { 'temp_f' => 72.0 },
          'forecast' => {
            'forecastday' => [
              {
                'date' => '2024-01-15',
                'day' => {
                  'maxtemp_f' => 75.0,
                  'mintemp_f' => 55.0,
                  'condition' => { 'text' => 'Sunny' }
                }
              }
            ]
          }
        }
      end

      before do
        stub_request(:get, %r{https://api.weatherapi.com/v1/forecast.json})
          .to_return(status: 200, body: forecast_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns forecast data' do
        result = client.fetch_forecast(latitude, longitude, days: 3)

        expect(result).to be_a(Hash)
        expect(result['forecast']).to have_key('forecastday')
        expect(result['forecast']['forecastday'].length).to eq(1)
      end

      it 'accepts custom number of days' do
        client.fetch_forecast(latitude, longitude, days: 5)

        expect(WebMock).to have_requested(:get, %r{https://api.weatherapi.com/v1/forecast.json})
          .with(query: hash_including('days' => '5'))
      end
    end
  end
end

