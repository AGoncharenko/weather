module Forecast
  class CacheKeyBuilder
    def initialize(address, geocoder_service = nil)
      @address = address
      @geocoder_service = geocoder_service
    end

    def call
      # Extract zip code from address string if present
      zip_match = @address.match(/\b(\d{5}(?:-\d{4})?)\b/)

      if zip_match
        # Use the extracted zip code as cache key
        "forecast:v1:#{zip_match[1]}"
      elsif zip_code?(@address)
        # Address is entirely a zip code, use it directly
        "forecast:v1:#{@address.downcase}"
      else
        # Get geocoding data to extract zip or city
        geo_data = geocoder_data
        return "forecast:v1:#{@address.downcase}" unless geo_data

        if geo_data[:zip] && !geo_data[:zip].empty?
          # Use zip code from geocoder response
          "forecast:v1:#{geo_data[:zip]}"
        elsif geo_data[:city] && !geo_data[:city].empty?
          # Use city from geocoder response if zip not available
          "forecast:v1:#{geo_data[:city].downcase}"
        else
          # Fallback to original address if neither zip nor city available
          "forecast:v1:#{@address.downcase}"
        end
      end
    end

    private

    def zip_code?(str)
      !!(str =~ /^\d{5}(-\d{4})?$/)
    end

    def geocoder_data
      return nil unless @geocoder_service&.respond_to?(:call)
      @geocoder_service.call
    rescue StandardError => e
      Rails.logger.warn("Geocoder service error: #{e.message}")
      nil
    end
  end
end
