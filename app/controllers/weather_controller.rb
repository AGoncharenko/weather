class WeatherController < ApplicationController
  before_action :validate_address, only: [ :create ]

  def index
  end

  def create
    render turbo_stream: turbo_stream.replace("forecast", partial: "weather/forecast", locals: { result: forecast_with_tracking })
  rescue => e
    Rails.logger.warn("Weather error for '#{params[:address]}': #{e.class} #{e.message}")
    render turbo_stream: turbo_stream.replace("forecast", partial: "weather/error", locals: { message: "Sorry, we couldn't fetch the forecast for that address." })
  end

  private def validate_address
    if address.blank?
      render turbo_stream: turbo_stream.replace(
        "forecast",
        partial: "weather/error",
        locals: { message: "Please enter an address or city." }
      )
    end
  end

  private def address
    @address ||= params[:address].to_s.strip
  end

  private def cache_key
    Forecast::CacheKeyBuilder.new(address, method(:geo)).call
  end

  private def forecast_with_tracking
    cache_hit = false

    cached_data = Rails.cache.read(cache_key)

    if cached_data
      cache_hit = true
      result = cached_data
    else
      result = forecast
    end

    result.merge(
      cache_hit: cache_hit,
      cached_at: cache_hit ? cached_data&.dig(:cached_at) : Time.current,
      cache_key: cache_key
    )
  end

  private def forecast
    Rails.cache.fetch(cache_key, expires_in: 30.minutes, race_condition_ttl: 10) do
      raise "Location not found" unless geo

      forecast = Forecast::GetForecast.call(geo[:lat], geo[:lon])
      raise "Forecast not available" unless forecast

      {
        address: address,
        resolved_name: geo[:name],
        latitude: geo[:lat],
        longitude: geo[:lon],
        current: forecast[:current],
        daily: forecast[:daily],
        cached_at: Time.current
      }
    end
  end

  private def geo
    @geo ||= Geocoder::GetCoordinates.call(address)
  end
end
