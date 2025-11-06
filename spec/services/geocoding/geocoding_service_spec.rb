# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geocoding::GeocodingService do
  let(:service) { described_class.new }
  let(:valid_address) { '1 Apple Park Way, Cupertino, CA 95014' }
  
  describe '#geocode_address' do
    context 'with a valid address' do
      let(:geocoder_result) do
        double(
          'Geocoder::Result',
          latitude: 37.3349,
          longitude: -122.0090,
          postal_code: '95014',
          zipcode: nil,
          address: '1 Apple Park Way, Cupertino, CA 95014, USA',
          city: 'Cupertino',
          state: 'California',
          country: 'United States',
          data: {}
        )
      end

      before do
        allow(Geocoder).to receive(:search).with(valid_address).and_return([geocoder_result])
      end

      it 'returns location information' do
        result = service.geocode_address(valid_address)

        expect(result).to be_a(Hash)
        expect(result[:latitude]).to eq(37.3349)
        expect(result[:longitude]).to eq(-122.0090)
        expect(result[:zip_code]).to eq('95014')
        expect(result[:city]).to eq('Cupertino')
        expect(result[:state]).to eq('California')
        expect(result[:country]).to eq('United States')
      end

      it 'caches the result' do
        # First call
        service.geocode_address(valid_address)
        
        # Second call should use cache
        expect(Geocoder).to receive(:search).with(valid_address).never
        service.geocode_address(valid_address)
      end
    end

    context 'with a blank address' do
      it 'raises GeocodingError' do
        expect {
          service.geocode_address('')
        }.to raise_error(Geocoding::GeocodingService::GeocodingError, 'Address cannot be blank')
      end
    end

    context 'when no results are found' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it 'raises GeocodingError' do
        expect {
          service.geocode_address('Invalid Address XYZ123')
        }.to raise_error(Geocoding::GeocodingService::GeocodingError, 'No location found for the given address')
      end
    end

    context 'when Geocoder raises an error' do
      before do
        allow(Geocoder).to receive(:search).and_raise(Geocoder::Error, 'API error')
      end

      it 'raises GeocodingError with appropriate message' do
        expect {
          service.geocode_address(valid_address)
        }.to raise_error(Geocoding::GeocodingService::GeocodingError, /Failed to geocode address/)
      end
    end

    context 'with different zip code field names' do
      let(:geocoder_result_with_postcode) do
        double(
          'Geocoder::Result',
          latitude: 51.5074,
          longitude: -0.1278,
          postal_code: nil,
          zipcode: nil,
          address: 'London, UK',
          city: 'London',
          state: 'England',
          country: 'United Kingdom',
          data: { 'address' => { 'postcode' => 'SW1A 1AA' } }
        )
      end

      before do
        allow(Geocoder).to receive(:search).and_return([geocoder_result_with_postcode])
      end

      it 'extracts zip code from data hash' do
        result = service.geocode_address('London, UK')
        expect(result[:zip_code]).to eq('SW1A 1AA')
      end
    end
  end

  describe 'cache key generation' do
    it 'generates consistent cache keys for same address with different cases' do
      allow(Geocoder).to receive(:search).and_return([
        double(
          latitude: 37.3349,
          longitude: -122.0090,
          postal_code: '95014',
          zipcode: nil,
          address: 'Address',
          city: 'City',
          state: 'State',
          country: 'Country',
          data: {}
        )
      ])

      service.geocode_address('Cupertino, CA')
      
      # This should use cached result despite different case
      expect(Geocoder).not_to receive(:search)
      service.geocode_address('CUPERTINO, CA')
    end
  end
end

