# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forecast::CacheKeyBuilder do
  let(:address) { 'New York, NY' }
  let(:geocoder_service) { nil }
  let(:service) { described_class.new(address, geocoder_service) }

  describe '#initialize' do
    it 'sets the address and geocoder_service instance variables' do
      geocoder_double = double('geocoder')
      service = described_class.new('Test Address', geocoder_double)

      expect(service.instance_variable_get(:@address)).to eq('Test Address')
      expect(service.instance_variable_get(:@geocoder_service)).to eq(geocoder_double)
    end

    it 'allows geocoder_service to be nil' do
      service = described_class.new('Test Address')

      expect(service.instance_variable_get(:@address)).to eq('Test Address')
      expect(service.instance_variable_get(:@geocoder_service)).to be_nil
    end
  end

  describe '#call' do
    subject { service.call }

    context 'when address contains a 5-digit zip code' do
      let(:address) { 'Some City, NY 12345' }

      it 'extracts and uses the zip code in cache key' do
        expect(subject).to eq('forecast:v1:12345')
      end
    end

    context 'when address contains a 9-digit zip code with dash' do
      let(:address) { '123 Main St, Springfield, IL 62701-1234' }

      it 'extracts and uses the full zip code in cache key' do
        expect(subject).to eq('forecast:v1:62701-1234')
      end
    end

    context 'when address contains multiple zip-like numbers' do
      let(:address) { '123 Main St, City 12345, State 67890' }

      it 'uses the first valid zip code found' do
        expect(subject).to eq('forecast:v1:12345')
      end
    end

    context 'when address is entirely a 5-digit zip code' do
      let(:address) { '10001' }

      it 'uses the zip code directly in lowercase' do
        expect(subject).to eq('forecast:v1:10001')
      end
    end

    context 'when address is entirely a 9-digit zip code' do
      let(:address) { '10001-1234' }

      it 'uses the zip code directly in lowercase' do
        expect(subject).to eq('forecast:v1:10001-1234')
      end
    end

    context 'when address has no extractable zip and no geocoder service' do
      let(:address) { 'New York City' }
      let(:geocoder_service) { nil }

      it 'uses the original address in lowercase' do
        expect(subject).to eq('forecast:v1:new york city')
      end
    end

    context 'when geocoder service is provided and returns data with zip' do
      let(:address) { 'Times Square, NYC' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_return({
          zip: '10036',
          city: 'New York'
        })
      end

      it 'uses the zip from geocoder data' do
        expect(subject).to eq('forecast:v1:10036')
      end
    end

    context 'when geocoder service returns data with empty zip but has city' do
      let(:address) { 'Central Park' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_return({
          zip: '',
          city: 'New York'
        })
      end

      it 'uses the city from geocoder data in lowercase' do
        expect(subject).to eq('forecast:v1:new york')
      end
    end

    context 'when geocoder service returns data with nil zip but has city' do
      let(:address) { 'Brooklyn Bridge' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_return({
          zip: nil,
          city: 'Brooklyn'
        })
      end

      it 'uses the city from geocoder data in lowercase' do
        expect(subject).to eq('forecast:v1:brooklyn')
      end
    end

    context 'when geocoder service returns data with empty city and zip' do
      let(:address) { 'Unknown Location' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_return({
          zip: '',
          city: ''
        })
      end

      it 'falls back to original address in lowercase' do
        expect(subject).to eq('forecast:v1:unknown location')
      end
    end

    context 'when geocoder service returns data with nil city and zip' do
      let(:address) { 'Nowhere' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_return({
          zip: nil,
          city: nil
        })
      end

      it 'falls back to original address in lowercase' do
        expect(subject).to eq('forecast:v1:nowhere')
      end
    end

    context 'when geocoder service returns nil' do
      let(:address) { 'Invalid Address' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_return(nil)
      end

      it 'falls back to original address in lowercase' do
        expect(subject).to eq('forecast:v1:invalid address')
      end
    end

    context 'when geocoder service does not respond to call' do
      let(:address) { 'Some Address' }
      let(:geocoder_service) { double('not_geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(false)
      end

      it 'falls back to original address in lowercase' do
        expect(subject).to eq('forecast:v1:some address')
      end
    end

    context 'when geocoder service raises an exception' do
      let(:address) { 'Error Address' }
      let(:geocoder_service) { double('geocoder') }

      before do
        allow(geocoder_service).to receive(:respond_to?).with(:call).and_return(true)
        allow(geocoder_service).to receive(:call).and_raise(StandardError, 'API Error')
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs the error and falls back to original address' do
        expect(subject).to eq('forecast:v1:error address')
        expect(Rails.logger).to have_received(:warn).with('Geocoder service error: API Error')
      end
    end

    context 'when geocoder service is nil' do
      let(:address) { 'Test Address' }
      let(:geocoder_service) { nil }

      it 'falls back to original address in lowercase' do
        expect(subject).to eq('forecast:v1:test address')
      end
    end

    context 'with mixed case addresses' do
      let(:address) { 'NEW YORK CITY' }

      it 'converts address to lowercase in cache key' do
        expect(subject).to eq('forecast:v1:new york city')
      end
    end
  end
end
