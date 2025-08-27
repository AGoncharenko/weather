# frozen_string_literal: true

require 'dotenv/load'
require 'opencage/geocoder'

module Geocoder
  class GetCoordinates
    def self.call(address)
      new(address).call
    end

    def initialize(address)
      @address = address
    end

    def call
      return nil unless @address.present?

      geocoder = OpenCage::Geocoder.new(api_key: ENV["OPENCAGE_API_KEY"])
      results = geocoder.geocode(@address)
      first = results.first
      return nil unless first

      {
        name: [ first.components["city"], first.components["state_code"], first.components["country"] ].compact.uniq.join(", "),
        zip: first.components["postcode"],
        lat: first.coordinates.first,
        lon: first.coordinates.second
      }
    end
  end
end
