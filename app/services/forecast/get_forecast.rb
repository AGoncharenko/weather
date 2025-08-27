# frozen_string_literal: true

require "open_meteo"

module Forecast
  class GetForecast
    def self.call(lat, lon)
      new(lat, lon).call
    end

    def initialize(lat, lon)
      @lat = lat
      @lon = lon
    end

    def call
      return nil unless @lat.present? && @lon.present?

      data = OpenMeteo::Forecast.new.get(location:, variables:)
      return nil unless data

      raw_json = data.raw_json
      current = raw_json["current"] || {}
      daily   = build_daily(raw_json["daily"])

      {
        current: {
          temperature: current["temperature"],
          windspeed: current["windspeed"],
          time: current["time"]
        },
        daily: daily
      }
    end

    private def location
      @location ||= OpenMeteo::Entities::Location.new(latitude: @lat.to_d, longitude: @lon.to_d)
    end

    private def variables
      {
        current: %i[temperature windspeed],
        daily: %i[temperature_2m_max temperature_2m_min precipitation_sum],
        timezone: "auto",
        temperature_unit: "fahrenheit",
        wind_speed_unit: "kmh",
        precipitation_unit: "mm",
        forecast_days: 7
      }
    end

    private def build_daily(daily_json)
      return [] unless daily_json && daily_json["time"]

      times  = daily_json["time"]
      tmax   = daily_json["temperature_2m_max"] || []
      tmin   = daily_json["temperature_2m_min"] || []
      precip = daily_json["precipitation_sum"] || []

      times.each_with_index.map do |t, i|
        { date: t, tmax: tmax[i], tmin: tmin[i], precipitation_mm: precip[i] }
      end
    end
  end
end
