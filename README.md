# Weather Forecast Application

A Rails 8 weather application that provides real-time weather forecasts and current conditions for any location worldwide. Built with Hotwire/Turbo for seamless user interactions and comprehensive caching for optimal performance.

## Features

- 🌦️ **Real-time Weather Data** - Current conditions and 7-day forecasts
- 🗺️ **Global Location Support** - Geocoding for addresses, cities, and zip codes worldwide
- ⚡ **Fast Response Times** - Intelligent caching with 30-minute TTL
- 🎯 **Smart Cache Keys** - Location-based caching with zip code prioritization
- 🔄 **Turbo-Powered UI** - No page refreshes, seamless user experience
- 📊 **Cache Analytics** - Track cache hits and performance metrics
- 🧪 **Comprehensive Testing** - Full RSpec test suite with VCR for API mocking

## Tech Stack

- **Backend**: Rails 8.0.2
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Styling**: CSS with Rails asset pipeline
- **Caching**: Rails.cache with Redis support
- **Testing**: RSpec with VCR for HTTP request mocking

## APIs Used

- **OpenCage Geocoding API** - Convert addresses to coordinates
- **Open-Meteo Weather API** - Fetch weather forecasts and current conditions

## Quick Start

### Prerequisites

- Ruby 3.3.2
- Rails 8.0.2
- Node.js (for asset compilation)
- OpenCage API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd weather
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Add your OpenCage API key to `.env`:
   ```
   OPENCAGE_API_KEY=your_api_key_here
   ```

4. **Start the development server**
   ```bash
   bin/dev
   ```

5. **Visit the application**
   Open [http://localhost:3000](http://localhost:3000)

## Usage

1. **Enter a location** - Type any address, city name, or zip code
2. **Get instant results** - Weather data appears without page refresh
3. **View detailed forecast** - See current conditions and 7-day outlook
4. **Cache indicators** - Green indicator shows cached results for faster loading

### Supported Location Formats

- Full addresses: "123 Main St, New York, NY 10001"
- City and state: "San Francisco, CA"
- City names: "London, UK"
- Zip codes: "90210" or "10001-1234"
- International locations: "Tokyo, Japan"

## Architecture

### Service Layer

The application uses a service-oriented architecture with three main services:

#### `Geocoder::GetCoordinates`
- Converts addresses to latitude/longitude coordinates
- Uses OpenCage Geocoding API
- Returns formatted location data with name normalization

#### `Forecast::GetForecast`
- Fetches weather data from Open-Meteo API
- Returns current conditions and 7-day forecast
- Handles temperature, wind speed, and precipitation data

#### `Forecast::CacheKeyBuilder`
- Generates intelligent cache keys based on location
- Prioritizes zip codes for consistent caching
- Falls back to city names and full addresses

### Caching Strategy

- **Cache Duration**: 30 minutes for weather data
- **Race Condition Protection**: 10-second TTL to prevent cache stampedes
- **Smart Keys**: Location-based keys prioritize zip codes for consistency
- **Cache Tracking**: Metadata tracks cache hits and performance

### Error Handling

- Graceful fallbacks for API failures
- User-friendly error messages
- Comprehensive logging for debugging
- Turbo stream error responses maintain UI consistency

## Testing

### Running the Test Suite

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/controllers/weather_controller_spec.rb
bundle exec rspec spec/services/geocoder/get_coordinates_spec.rb
bundle exec rspec spec/services/forecast/get_forecast_spec.rb
bundle exec rspec spec/services/forecast/cache_key_builder_spec.rb
```

### Test Coverage

- **Controllers**: Full request/response cycle testing
- **Services**: Unit tests with comprehensive edge case coverage  
- **Error Handling**: Exception scenarios and fallback behavior
- **Caching**: Cache hit/miss scenarios and key generation
- **API Mocking**: VCR cassettes for reliable, fast tests

### VCR Cassettes

HTTP interactions are recorded in VCR cassettes for consistent testing:
- `spec/cassettes/geocoder/` - Geocoding API responses
- `spec/cassettes/forecast/` - Weather API responses

## Configuration

### Environment Variables

```bash
# Required
OPENCAGE_API_KEY=your_opencage_api_key

# Optional (for production)
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=your_secret_key
```

### Cache Configuration

The application supports multiple cache backends:

```ruby
# Development (default)
config.cache_store = :solid_cache_store

# Production with Redis
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

## API Rate Limits

- **OpenCage Geocoding**: 2,500 requests/day (free tier)
- **Open-Meteo**: Unlimited for non-commercial use
- **Caching**: Reduces API calls by ~80% with 30-minute cache TTL

### Development Guidelines

- Write comprehensive tests for new features
- Follow existing code style and patterns
- Update documentation for API changes
- Use meaningful commit messages
- Test with real API calls in development

### Logs

Development logs are available at:
- `log/development.log` - Application logs
- `log/test.log` - Test execution logs

### Demo
https://www.loom.com/share/d3df26dfb4de4d8d80d10df2ba92f597?sid=a10db13d-5e7e-4a3a-bb38-6a720ac7d9f2

