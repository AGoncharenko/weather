# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "POST #create" do
    let(:valid_address) { "New York, NY" }
    let(:blank_address) { "" }

    context "with valid address" do
      let(:geo_data) do
        {
          name: "New York, NY, United States",
          zip: "10001",
          lat: 40.7128,
          lon: -74.0060
        }
      end

      let(:forecast_data) do
        {
          current: {
            temperature: 72.0,
            windspeed: 10.0,
            time: "2025-08-26T14:00:00Z"
          },
          daily: [
            { date: "2025-08-26", tmax: 75.0, tmin: 65.0, precipitation_mm: 0.0 },
            { date: "2025-08-27", tmax: 78.0, tmin: 68.0, precipitation_mm: 2.5 }
          ]
        }
      end

      before do
        allow(Geocoder::GetCoordinates).to receive(:call).with(valid_address).and_return(geo_data)
        allow(Forecast::GetForecast).to receive(:call).with(geo_data[:lat], geo_data[:lon]).and_return(forecast_data)
        allow(Rails.cache).to receive(:read).and_return(nil)
        allow(Rails.cache).to receive(:fetch).and_yield
      end

      it "returns http success" do
        post :create, params: { address: valid_address }
        expect(response).to have_http_status(:success)
      end

      it "renders turbo stream response" do
        post :create, params: { address: valid_address }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "replaces the forecast element with forecast partial" do
        post :create, params: { address: valid_address }
        expect(response.body).to include('turbo-stream action="replace" target="forecast"')
      end

      it "calls geocoder service with the address" do
        post :create, params: { address: valid_address }
        expect(Geocoder::GetCoordinates).to have_received(:call).with(valid_address)
      end

      it "calls forecast service with coordinates" do
        post :create, params: { address: valid_address }
        expect(Forecast::GetForecast).to have_received(:call).with(geo_data[:lat], geo_data[:lon])
      end
    end

    context "with blank address" do
      before do
        allow(Geocoder::GetCoordinates).to receive(:call)
      end

      it "renders error turbo stream due to validation" do
        post :create, params: { address: blank_address }
        expect(response.body).to include('turbo-stream action="replace" target="forecast"')
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "does not call geocoder service" do
        post :create, params: { address: blank_address }
        expect(Geocoder::GetCoordinates).not_to have_received(:call)
      end
    end

    context "when geocoder returns nil (location not found)" do
      before do
        allow(Geocoder::GetCoordinates).to receive(:call).with(valid_address).and_return(nil)
        allow(Rails.logger).to receive(:warn)
      end

      it "renders error turbo stream" do
        post :create, params: { address: valid_address }
        expect(response.body).to include('turbo-stream action="replace" target="forecast"')
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "logs the error" do
        post :create, params: { address: valid_address }
        expect(Rails.logger).to have_received(:warn).with(
          match(/Weather error for '#{valid_address}'.*Location not found/)
        )
      end
    end

    context "when forecast service returns nil" do
      before do
        geo_data = { lat: 40.7128, lon: -74.0060, name: "New York" }
        allow(Geocoder::GetCoordinates).to receive(:call).with(valid_address).and_return(geo_data)
        allow(Forecast::GetForecast).to receive(:call).with(geo_data[:lat], geo_data[:lon]).and_return(nil)
        allow(Rails.cache).to receive(:read).and_return(nil)
        allow(Rails.cache).to receive(:fetch).and_yield
        allow(Rails.logger).to receive(:warn)
      end

      it "renders error turbo stream" do
        post :create, params: { address: valid_address }
        expect(response.body).to include('turbo-stream action="replace" target="forecast"')
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "logs the error" do
        post :create, params: { address: valid_address }
        expect(Rails.logger).to have_received(:warn).with(
          match(/Weather error for '#{valid_address}'.*Forecast not available/)
        )
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(Geocoder::GetCoordinates).to receive(:call).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:warn)
      end

      it "renders error turbo stream" do
        post :create, params: { address: valid_address }
        expect(response.body).to include('turbo-stream action="replace" target="forecast"')
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "logs the specific error" do
        post :create, params: { address: valid_address }
        expect(Rails.logger).to have_received(:warn).with(
          "Weather error for '#{valid_address}': StandardError API Error"
        )
      end
    end
  end
end
