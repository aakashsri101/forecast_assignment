# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
  describe 'GET #index' do
    it 'returns success response' do
      get :index
      expect(response).to be_successful
    end

    it 'renders index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'POST #create' do
    let(:address) { '1 Apple Park Way, Cupertino, CA 95014' }
    
    let(:facade_result) do
      {
        forecast: {
          zip_code: '95014',
          location: { name: 'Cupertino' },
          current: { temperature_f: 72.0, condition: 'Sunny' },
          forecast: [{ date: '2024-01-15' }]
        },
        location: {
          latitude: 37.3349,
          longitude: -122.0090,
          zip_code: '95014',
          city: 'Cupertino',
          state: 'California'
        },
        from_cache: false,
        cached_at: Time.current,
        expires_at: Time.current + 30.minutes
      }
    end

    context 'with valid address' do
      before do
        allow(WeatherForecastFacade).to receive(:get_forecast).with(address).and_return(facade_result)
      end

      it 'calls facade with address' do
        post :create, params: { address: address }
        
        expect(WeatherForecastFacade).to have_received(:get_forecast).with(address)
      end

      it 'assigns forecast data' do
        post :create, params: { address: address }
        
        expect(assigns(:forecast_data)).to eq(facade_result[:forecast])
      end

      it 'assigns location info' do
        post :create, params: { address: address }
        
        expect(assigns(:location_info)).to eq(facade_result[:location])
      end

      it 'assigns cache status' do
        post :create, params: { address: address }
        
        expect(assigns(:from_cache)).to be false
      end

      it 'renders show template' do
        post :create, params: { address: address }
        
        expect(response).to render_template(:show)
      end
    end

    context 'with blank address' do
      it 'sets error flash message' do
        post :create, params: { address: '' }
        
        expect(flash.now[:error]).to eq('Please enter an address to get the forecast.')
      end

      it 'renders index template' do
        post :create, params: { address: '' }
        
        expect(response).to render_template(:index)
      end

      it 'does not call facade' do
        allow(WeatherForecastFacade).to receive(:get_forecast)
        
        post :create, params: { address: '' }
        
        expect(WeatherForecastFacade).not_to have_received(:get_forecast)
      end
    end

    context 'when geocoding fails' do
      before do
        allow(WeatherForecastFacade).to receive(:get_forecast)
          .and_raise(Geocoding::GeocodingService::GeocodingError, 'Location not found')
      end

      it 'sets error flash message' do
        post :create, params: { address: address }
        
        expect(flash.now[:error]).to eq('Unable to find location: Location not found')
      end

      it 'renders index template' do
        post :create, params: { address: address }
        
        expect(response).to render_template(:index)
      end

      it 'logs warning' do
        allow(Rails.logger).to receive(:warn)
        
        post :create, params: { address: address }
        
        expect(Rails.logger).to have_received(:warn).with(/Geocoding error/)
      end
    end

    context 'when weather API fails' do
      before do
        allow(WeatherForecastFacade).to receive(:get_forecast)
          .and_raise(Weather::WeatherApiError, 'API quota exceeded')
      end

      it 'sets error flash message' do
        post :create, params: { address: address }
        
        expect(flash.now[:error]).to eq('Unable to retrieve weather data: API quota exceeded')
      end

      it 'renders index template' do
        post :create, params: { address: address }
        
        expect(response).to render_template(:index)
      end

      it 'logs error' do
        allow(Rails.logger).to receive(:error)
        
        post :create, params: { address: address }
        
        expect(Rails.logger).to have_received(:error).with(/Weather API error/)
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(WeatherForecastFacade).to receive(:get_forecast)
          .and_raise(StandardError, 'Unexpected error')
        allow(Rails.logger).to receive(:error)
      end

      it 'sets generic error flash message' do
        post :create, params: { address: address }
        
        expect(flash.now[:error]).to eq('An unexpected error occurred. Please try again later.')
      end

      it 'renders index template' do
        post :create, params: { address: address }
        
        expect(response).to render_template(:index)
      end

      it 'logs error with backtrace' do
        post :create, params: { address: address }
        
        expect(Rails.logger).to have_received(:error).at_least(:once)
      end
    end

    context 'with cached result' do
      let(:cached_result) do
        facade_result.merge(from_cache: true, cached_at: Time.current - 10.minutes)
      end

      before do
        allow(WeatherForecastFacade).to receive(:get_forecast).and_return(cached_result)
      end

      it 'assigns cache status as true' do
        post :create, params: { address: address }
        
        expect(assigns(:from_cache)).to be true
      end

      it 'assigns cached_at timestamp' do
        post :create, params: { address: address }
        
        expect(assigns(:cached_at)).to be_a(Time)
      end
    end
  end
end

