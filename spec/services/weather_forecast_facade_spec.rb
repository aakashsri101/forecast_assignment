# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherForecastFacade do
  let(:address) { '1 Apple Park Way, Cupertino, CA 95014' }
  
  let(:location_info) do
    {
      latitude: 37.3349,
      longitude: -122.0090,
      zip_code: '95014',
      formatted_address: '1 Apple Park Way, Cupertino, CA 95014, USA',
      city: 'Cupertino',
      state: 'California',
      country: 'United States'
    }
  end

  let(:weather_data) do
    {
      zip_code: '95014',
      location: { name: 'Cupertino' },
      current: { temperature_f: 72.0 },
      forecast: [{ date: '2024-01-15' }],
      retrieved_at: Time.current
    }
  end

  let(:geocoding_service) { instance_double(Geocoding::GeocodingService) }
  let(:weather_service) { instance_double(Weather::WeatherService) }
  let(:cache_service) { instance_double(Caching::ForecastCacheService) }

  before do
    described_class.reset_services!
    allow(Geocoding::GeocodingService).to receive(:new).and_return(geocoding_service)
    allow(Weather::WeatherService).to receive(:new).and_return(weather_service)
    allow(Caching::ForecastCacheService).to receive(:new).and_return(cache_service)
  end

  describe '.get_forecast' do
    context 'with valid address' do
      before do
        allow(geocoding_service).to receive(:geocode_address).with(address).and_return(location_info)
        allow(weather_service).to receive(:get_weather_for_location).and_return(weather_data)
        allow(cache_service).to receive(:fetch_or_store).and_yield.and_return(
          forecast: weather_data,
          from_cache: false,
          cached_at: Time.current,
          expires_at: Time.current + 30.minutes
        )
      end

      it 'coordinates all services' do
        result = described_class.get_forecast(address)

        expect(geocoding_service).to have_received(:geocode_address).with(address)
        expect(weather_service).to have_received(:get_weather_for_location)
          .with(location_info[:latitude], location_info[:longitude], location_info[:zip_code])
      end

      it 'returns complete result with all data' do
        result = described_class.get_forecast(address)

        expect(result).to have_key(:forecast)
        expect(result).to have_key(:location)
        expect(result).to have_key(:from_cache)
        expect(result).to have_key(:cached_at)
        expect(result).to have_key(:expires_at)
      end

      it 'includes location information in result' do
        result = described_class.get_forecast(address)

        expect(result[:location]).to eq(location_info)
      end

      it 'includes forecast data in result' do
        result = described_class.get_forecast(address)

        expect(result[:forecast]).to eq(weather_data)
      end

      it 'includes cache metadata' do
        result = described_class.get_forecast(address)

        expect(result[:from_cache]).to be false
        expect(result[:cached_at]).to be_a(Time)
        expect(result[:expires_at]).to be_a(Time)
      end
    end

    context 'with cached data' do
      before do
        allow(geocoding_service).to receive(:geocode_address).with(address).and_return(location_info)
        allow(cache_service).to receive(:fetch_or_store).and_return(
          forecast: weather_data,
          from_cache: true,
          cached_at: Time.current - 10.minutes,
          expires_at: Time.current + 20.minutes
        )
      end

      it 'does not call weather service' do
        described_class.get_forecast(address)

        expect(weather_service).not_to have_received(:get_weather_for_location)
      end

      it 'indicates data is from cache' do
        result = described_class.get_forecast(address)

        expect(result[:from_cache]).to be true
      end

      it 'includes cache timestamp' do
        result = described_class.get_forecast(address)

        expect(result[:cached_at]).to be_a(Time)
      end
    end

    context 'when geocoding fails' do
      before do
        allow(geocoding_service).to receive(:geocode_address)
          .and_raise(Geocoding::GeocodingService::GeocodingError, 'Address not found')
      end

      it 'propagates geocoding error' do
        expect {
          described_class.get_forecast(address)
        }.to raise_error(Geocoding::GeocodingService::GeocodingError, 'Address not found')
      end

      it 'does not call weather service' do
        begin
          described_class.get_forecast(address)
        rescue Geocoding::GeocodingService::GeocodingError
          # Expected error
        end

        expect(weather_service).not_to have_received(:get_weather_for_location)
      end
    end

    context 'when weather API fails' do
      before do
        allow(geocoding_service).to receive(:geocode_address).and_return(location_info)
        allow(cache_service).to receive(:fetch_or_store).and_yield
        allow(weather_service).to receive(:get_weather_for_location)
          .and_raise(Weather::WeatherApiError, 'API error')
      end

      it 'propagates weather API error' do
        expect {
          described_class.get_forecast(address)
        }.to raise_error(Weather::WeatherApiError, 'API error')
      end
    end
  end

  describe '.clear_cache' do
    before do
      allow(cache_service).to receive(:clear_cache_for_zip).and_return(true)
    end

    it 'delegates to cache service' do
      described_class.clear_cache('95014')

      expect(cache_service).to have_received(:clear_cache_for_zip).with('95014')
    end

    it 'returns result from cache service' do
      result = described_class.clear_cache('95014')

      expect(result).to be true
    end
  end

  describe 'service memoization' do
    it 'reuses geocoding service instance' do
      expect(Geocoding::GeocodingService).to receive(:new).once.and_return(geocoding_service)

      # Access service multiple times
      described_class.send(:geocoding_service)
      described_class.send(:geocoding_service)
    end

    it 'reuses weather service instance' do
      expect(Weather::WeatherService).to receive(:new).once.and_return(weather_service)

      described_class.send(:weather_service)
      described_class.send(:weather_service)
    end

    it 'reuses cache service instance' do
      expect(Caching::ForecastCacheService).to receive(:new).once.and_return(cache_service)

      described_class.send(:cache_service)
      described_class.send(:cache_service)
    end
  end

  describe '.reset_services!' do
    before do
      # Initialize services
      described_class.send(:geocoding_service)
      described_class.send(:weather_service)
      described_class.send(:cache_service)
    end

    it 'resets all service instances' do
      described_class.reset_services!

      # Should create new instances
      expect(Geocoding::GeocodingService).to receive(:new).and_return(geocoding_service)
      expect(Weather::WeatherService).to receive(:new).and_return(weather_service)
      expect(Caching::ForecastCacheService).to receive(:new).and_return(cache_service)

      described_class.send(:geocoding_service)
      described_class.send(:weather_service)
      described_class.send(:cache_service)
    end
  end
end

