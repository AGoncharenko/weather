# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geocoder::GetCoordinates do
  let(:address) { 'New York, NY' }

  describe '.call' do
    it 'creates a new instance and calls #call' do
      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(address).and_return(service_instance)
      allow(service_instance).to receive(:call).and_return({ lat: 40.7128, lon: -74.0060 })

      result = described_class.call(address)

      expect(described_class).to have_received(:new).with(address)
      expect(service_instance).to have_received(:call)
      expect(result).to eq({ lat: 40.7128, lon: -74.0060 })
    end
  end

  describe '#call' do
    subject { service.call }

    let(:service) { described_class.new(address) }

    context 'when address is nil' do
      let(:address) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when address is empty string' do
      let(:address) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when address is blank (whitespace)' do
      let(:address) { '   ' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when address is present', :vcr do
      let(:address) { 'New York, NY' }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENCAGE_API_KEY").and_return('fake_api_key_for_testing')
      end

      it 'returns a hash with coordinates and location details' do
        VCR.use_cassette('geocoder/new_york_success') do
          result = subject

          expect(result).to be_a(Hash)
          expect(result).to have_key(:name)
          expect(result).to have_key(:zip)
          expect(result).to have_key(:lat)
          expect(result).to have_key(:lon)
          expect(result[:lat]).to be_a(Float)
          expect(result[:lon]).to be_a(Float)
        end
      end
    end

    context 'when geocoding a specific address', :vcr do
      let(:address) { 'San Francisco, CA' }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENCAGE_API_KEY").and_return('fake_api_key_for_testing')
      end

      it 'returns coordinates for San Francisco' do
        VCR.use_cassette('geocoder/san_francisco_success') do
          result = subject

          expect(result).to be_a(Hash)
          expect(result[:name]).to include('San Francisco')
          expect(result[:lat]).to be_between(37.0, 38.0)  # Approximate latitude range for SF
          expect(result[:lon]).to be_between(-123.0, -122.0)  # Approximate longitude range for SF
        end
      end
    end

    context 'when geocoding an invalid address', :vcr do
      let(:address) { 'InvalidCityThatDoesNotExist12345' }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENCAGE_API_KEY").and_return('fake_api_key_for_testing')
      end

      it 'returns nil for addresses that cannot be geocoded' do
        VCR.use_cassette('geocoder/invalid_address') do
          expect(subject).to be_nil
        end
      end
    end

    context 'when API returns an error', :vcr do
      let(:address) { 'Test Address' }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENCAGE_API_KEY").and_return('invalid_key')
      end

      it 'handles API errors gracefully' do
        VCR.use_cassette('geocoder/api_error') do
          expect { subject }.to raise_error(StandardError)
        end
      end
    end

    context 'when ENV["OPENCAGE_API_KEY"] is missing' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENCAGE_API_KEY").and_return(nil)
      end

      it 'creates geocoder with nil api_key and raises VCR error when trying to make HTTP request' do
        VCR.use_cassette('geocoder/missing_api_key') do
          # When API key is nil, OpenCage will still try to make an HTTP request
          # but VCR will catch it since we have allow_http_connections_when_no_cassette = false
          expect { subject }.to raise_error(OpenCage::Error::AuthenticationError)
        end
      end
    end
  end

  describe '#initialize' do
    it 'sets the address instance variable' do
      service = described_class.new('Test Address')
      expect(service.instance_variable_get(:@address)).to eq('Test Address')
    end
  end
end
