# Geocoder configuration
# Documentation: https://github.com/alexreisner/geocoder

Geocoder.configure(
  # Geocoding service (defaults to :nominatim)
  lookup: :nominatim,

  # Geocoding service request timeout, in seconds (default 3):
  timeout: 5,

  # Set default units to miles:
  units: :mi,

  # Caching (see Caching section for details):
  cache: Rails.cache,
  cache_prefix: 'geocoder:',

  # API key for geocoding service (if required)
  # api_key: ENV['GEOCODING_API_KEY'],

  # Set a user agent for requests
  http_headers: { 'User-Agent' => 'WeatherForecastApp' },

  # Use HTTPS for geocoding requests
  use_https: true,

  # Language for results (ISO 639-1 code)
  # language: :en,

  # Always raise Geocoder::LookupError on failure
  # always_raise: [],

  # Calculation options
  distances: :linear
)

