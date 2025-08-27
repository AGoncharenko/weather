# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forecast::GetForecast do
  let(:lat) { 40.7128 }
  let(:lon) { -74.0060 }

  describe '.call' do
    it 'creates a new instance and calls #call' do
      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(lat, lon).and_return(service_instance)
      allow(service_instance).to receive(:call).and_return({ current: {}, daily: [] })

      result = described_class.call(lat, lon)

      expect(described_class).to have_received(:new).with(lat, lon)
      expect(service_instance).to have_received(:call)
      expect(result).to eq({ current: {}, daily: [] })
    end
  end

  describe '#initialize' do
    it 'sets the latitude and longitude instance variables' do
      service = described_class.new(lat, lon)
      expect(service.instance_variable_get(:@lat)).to eq(lat)
      expect(service.instance_variable_get(:@lon)).to eq(lon)
    end
  end

  describe '#call' do
    subject { service.call }

    let(:service) { described_class.new(lat, lon) }

    context 'when latitude is nil' do
      let(:lat) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when longitude is nil' do
      let(:lon) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when both coordinates are nil' do
      let(:lat) { nil }
      let(:lon) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when latitude is empty string' do
      let(:lat) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when longitude is empty string' do
      let(:lon) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when coordinates are present', :vcr do
      let(:lat) { 40.7128 }
      let(:lon) { -74.0060 }

      it 'returns forecast data with current and daily information' do
        VCR.use_cassette('forecast/new_york_success') do
          result = subject

          expect(result).to be_a(Hash)
          expect(result.keys).to include(:current, :daily)

          # Current weather structure
          expect(result[:current]).to be_a(Hash)
          expect(result[:current].keys).to include(:temperature, :windspeed, :time)

          # Daily forecast structure
          expect(result[:daily]).to be_an(Array)
          daily_item = result[:daily].first
          expect(daily_item.keys).to include(:date, :tmax, :tmin, :precipitation_mm)
        end
      end
    end

    context 'when OpenMeteo API returns no data', :vcr do
      let(:lat) { 999.0 }  # Invalid coordinates
      let(:lon) { 999.0 }

      before do
        # Mock OpenMeteo to return nil
        forecast_client = instance_double(OpenMeteo::Forecast)
        allow(OpenMeteo::Forecast).to receive(:new).and_return(forecast_client)
        allow(forecast_client).to receive(:get).and_return(nil)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when OpenMeteo API returns empty data', :vcr do
      let(:lat) { 40.7128 }
      let(:lon) { -74.0060 }

      before do
        # Mock OpenMeteo to return data with empty raw_json
        forecast_data = instance_double('ForecastData')
        allow(forecast_data).to receive(:raw_json).and_return({})

        forecast_client = instance_double(OpenMeteo::Forecast)
        allow(OpenMeteo::Forecast).to receive(:new).and_return(forecast_client)
        allow(forecast_client).to receive(:get).and_return(forecast_data)
      end

      it 'returns formatted data with empty current and daily sections' do
        result = subject

        expect(result).to eq({
          current: {
            temperature: nil,
            windspeed: nil,
            time: nil
          },
          daily: []
        })
      end
    end

    context 'when API returns data with missing current section', :vcr do
      let(:lat) { 40.7128 }
      let(:lon) { -74.0060 }

      before do
        raw_data = {
          "daily" => {
            "time" => [ "2025-08-26", "2025-08-27" ],
            "temperature_2m_max" => [ 75.0, 78.0 ],
            "temperature_2m_min" => [ 65.0, 68.0 ],
            "precipitation_sum" => [ 0.0, 2.5 ]
          }
        }

        forecast_data = instance_double('ForecastData')
        allow(forecast_data).to receive(:raw_json).and_return(raw_data)

        forecast_client = instance_double(OpenMeteo::Forecast)
        allow(OpenMeteo::Forecast).to receive(:new).and_return(forecast_client)
        allow(forecast_client).to receive(:get).and_return(forecast_data)
      end

      it 'returns data with nil current values and populated daily data' do
        result = subject

        expect(result[:current]).to eq({
          temperature: nil,
          windspeed: nil,
          time: nil
        })

        expect(result[:daily]).to eq([
          { date: "2025-08-26", tmax: 75.0, tmin: 65.0, precipitation_mm: 0.0 },
          { date: "2025-08-27", tmax: 78.0, tmin: 68.0, precipitation_mm: 2.5 }
        ])
      end
    end

    context 'when API returns data with missing daily section', :vcr do
      let(:lat) { 40.7128 }
      let(:lon) { -74.0060 }

      before do
        raw_data = {
          "current" => {
            "temperature" => 72.5,
            "windspeed" => 10.2,
            "time" => "2025-08-26T14:00:00Z"
          }
        }

        forecast_data = instance_double('ForecastData')
        allow(forecast_data).to receive(:raw_json).and_return(raw_data)

        forecast_client = instance_double(OpenMeteo::Forecast)
        allow(OpenMeteo::Forecast).to receive(:new).and_return(forecast_client)
        allow(forecast_client).to receive(:get).and_return(forecast_data)
      end

      it 'returns data with populated current values and empty daily array' do
        result = subject

        expect(result[:current]).to eq({
          temperature: 72.5,
          windspeed: 10.2,
          time: "2025-08-26T14:00:00Z"
        })

        expect(result[:daily]).to eq([])
      end
    end
  end
end
