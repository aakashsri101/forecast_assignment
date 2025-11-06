# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Caching::ForecastCacheService do
  let(:service) { described_class.new }
  let(:zip_code) { '95014' }
  
  let(:forecast_data) do
    {
      zip_code: zip_code,
      location: { name: 'Cupertino' },
      current: { temperature_f: 72.0 },
      forecast: [{ date: '2024-01-15' }],
      retrieved_at: Time.current
    }
  end

  before do
    Rails.cache.clear
  end

  describe '#fetch_or_store' do
    context 'on cache miss' do
      it 'executes the block and stores result' do
        block_executed = false
        
        result = service.fetch_or_store(zip_code) do
          block_executed = true
          forecast_data
        end

        expect(block_executed).to be true
        expect(result[:forecast]).to eq(forecast_data)
        expect(result[:from_cache]).to be false
      end

      it 'includes cache metadata' do
        result = service.fetch_or_store(zip_code) { forecast_data }

        expect(result).to have_key(:cached_at)
        expect(result).to have_key(:expires_at)
        expect(result[:cached_at]).to be_a(Time)
        expect(result[:expires_at]).to be_a(Time)
      end

      it 'calculates correct expiration time' do
        result = service.fetch_or_store(zip_code) { forecast_data }

        expected_expiration = result[:cached_at] + 30.minutes
        expect(result[:expires_at]).to be_within(1.second).of(expected_expiration)
      end

      it 'logs cache miss' do
        allow(Rails.logger).to receive(:info)

        service.fetch_or_store(zip_code) { forecast_data }

        expect(Rails.logger).to have_received(:info).with("Cache MISS for zip code: #{zip_code}")
      end
    end

    context 'on cache hit' do
      before do
        # Populate cache
        service.fetch_or_store(zip_code) { forecast_data }
      end

      it 'returns cached data without executing block' do
        block_executed = false

        result = service.fetch_or_store(zip_code) do
          block_executed = true
          { different: 'data' }
        end

        expect(block_executed).to be false
        expect(result[:forecast]).to eq(forecast_data)
        expect(result[:from_cache]).to be true
      end

      it 'logs cache hit' do
        allow(Rails.logger).to receive(:info)

        service.fetch_or_store(zip_code) { forecast_data }

        expect(Rails.logger).to have_received(:info).with("Cache HIT for zip code: #{zip_code}")
      end

      it 'includes original cached_at timestamp' do
        first_result = service.fetch_or_store(zip_code) { forecast_data }
        
        # Wait a moment
        sleep 0.1
        
        second_result = service.fetch_or_store(zip_code) { forecast_data }

        expect(second_result[:cached_at]).to eq(first_result[:cached_at])
      end
    end

    context 'with blank zip code' do
      it 'raises ArgumentError' do
        expect {
          service.fetch_or_store('') { forecast_data }
        }.to raise_error(ArgumentError, 'Zip code cannot be blank')
      end
    end

    context 'with different zip code formats' do
      it 'normalizes zip codes for consistent caching' do
        # Store with one format
        service.fetch_or_store('95014') { forecast_data }

        # Should hit cache with different formatting
        block_executed = false
        result = service.fetch_or_store(' 95014 ') do
          block_executed = true
          { different: 'data' }
        end

        expect(block_executed).to be false
        expect(result[:from_cache]).to be true
      end
    end

    context 'when cache read fails' do
      before do
        allow(Rails.cache).to receive(:read).and_raise(StandardError, 'Cache error')
        allow(Rails.logger).to receive(:error)
      end

      it 'executes block and continues' do
        result = service.fetch_or_store(zip_code) { forecast_data }

        expect(result[:forecast]).to eq(forecast_data)
        expect(result[:from_cache]).to be false
      end

      it 'logs the error' do
        service.fetch_or_store(zip_code) { forecast_data }

        expect(Rails.logger).to have_received(:error).with(/Error reading from cache/)
      end
    end

    context 'when cache write fails' do
      before do
        allow(Rails.cache).to receive(:write).and_raise(StandardError, 'Write error')
        allow(Rails.logger).to receive(:error)
      end

      it 'still returns the data' do
        result = service.fetch_or_store(zip_code) { forecast_data }

        expect(result[:forecast]).to eq(forecast_data)
      end

      it 'logs the error' do
        service.fetch_or_store(zip_code) { forecast_data }

        expect(Rails.logger).to have_received(:error).with(/Error writing to cache/)
      end
    end
  end

  describe '#clear_cache_for_zip' do
    before do
      service.fetch_or_store(zip_code) { forecast_data }
    end

    it 'clears cache for specific zip code' do
      service.clear_cache_for_zip(zip_code)

      # Should be cache miss now
      block_executed = false
      service.fetch_or_store(zip_code) do
        block_executed = true
        forecast_data
      end

      expect(block_executed).to be true
    end

    it 'logs cache clearing' do
      allow(Rails.logger).to receive(:info)

      service.clear_cache_for_zip(zip_code)

      expect(Rails.logger).to have_received(:info).with("Cache cleared for zip code: #{zip_code}")
    end

    it 'returns true' do
      expect(service.clear_cache_for_zip(zip_code)).to be true
    end
  end

  describe '#clear_all_caches' do
    before do
      service.fetch_or_store('95014') { forecast_data }
      service.fetch_or_store('94043') { forecast_data.merge(zip_code: '94043') }
    end

    it 'clears all forecast caches' do
      service.clear_all_caches

      # Both should be cache misses now
      block_count = 0
      
      service.fetch_or_store('95014') do
        block_count += 1
        forecast_data
      end
      
      service.fetch_or_store('94043') do
        block_count += 1
        forecast_data
      end

      expect(block_count).to eq(2)
    end

    it 'logs cache clearing' do
      allow(Rails.logger).to receive(:info)

      service.clear_all_caches

      expect(Rails.logger).to have_received(:info).with('All forecast caches cleared')
    end

    it 'returns true' do
      expect(service.clear_all_caches).to be true
    end
  end

  describe 'cache expiration' do
    it 'sets correct expiration time' do
      service.fetch_or_store(zip_code) { forecast_data }

      # Verify cache key exists
      cache_key = "weather_forecast:#{zip_code}"
      cached_entry = Rails.cache.read(cache_key)
      
      expect(cached_entry).not_to be_nil
    end
  end
end

