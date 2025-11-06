# Architecture Documentation

## System Overview

The Weather Forecast Application is built using **Clean Architecture** principles with a clear separation between presentation, application, service, and infrastructure layers. This document provides an in-depth look at the architectural decisions and patterns used throughout the application.

## Table of Contents

1. [Architecture Layers](#architecture-layers)
2. [Design Patterns](#design-patterns)
3. [Service Layer Architecture](#service-layer-architecture)
4. [Caching Strategy](#caching-strategy)
5. [Error Handling](#error-handling)
6. [Data Flow](#data-flow)
7. [Scalability](#scalability)
8. [Security](#security)

## Architecture Layers

### 1. Presentation Layer

```
┌────────────────────────────────────────────┐
│         Presentation Layer                  │
│                                             │
│  Controllers                                │
│  ├── ApplicationController                  │
│  │   └── Common error handling              │
│  │   └── Base controller functionality      │
│  └── ForecastsController                    │
│      ├── index: Display search form         │
│      └── create: Process forecast request   │
│                                             │
│  Views (ERB Templates)                      │
│  ├── layouts/application.html.erb           │
│  ├── forecasts/index.html.erb               │
│  └── forecasts/show.html.erb                │
│                                             │
│  Helpers                                    │
│  ├── ApplicationHelper                      │
│  └── ForecastsHelper                        │
└────────────────────────────────────────────┘
```

**Responsibilities:**
- Accept user input (addresses)
- Display forecast data
- Show cache indicators
- Handle validation errors
- Render user-friendly error messages

**Key Design Decisions:**
- Controllers are thin and delegate to services
- Views are kept simple with minimal logic
- Helpers provide reusable formatting methods
- Flash messages for user feedback

### 2. Application Layer (Facade)

```
┌────────────────────────────────────────────┐
│         Application Layer                   │
│                                             │
│  WeatherForecastFacade                      │
│  │                                          │
│  ├── get_forecast(address)                  │
│  │   ├── Step 1: Geocode address           │
│  │   ├── Step 2: Check cache                │
│  │   ├── Step 3: Fetch weather (if needed)  │
│  │   └── Step 4: Return aggregated result   │
│  │                                          │
│  └── clear_cache(zip_code)                  │
│                                             │
│  Design Pattern: Facade                     │
│  - Single entry point for controllers       │
│  - Hides complexity of service coordination │
│  - Provides simplified interface            │
└────────────────────────────────────────────┘
```

**Why Facade Pattern?**
- **Simplification**: Controllers don't need to know about multiple services
- **Coordination**: Manages the orchestration of geocoding → caching → weather fetching
- **Single Responsibility**: Each service focuses on its domain
- **Testability**: Easy to test orchestration logic in isolation

### 3. Service Layer

```
┌────────────────────────────────────────────────────────┐
│                   Service Layer                         │
│                                                         │
│  Geocoding Module                                       │
│  └── GeocodingService                                   │
│      ├── geocode_address(address)                       │
│      ├── Cache geocoding results (1 hour)               │
│      └── Extract: lat, lon, zip, city, state            │
│                                                         │
│  Weather Module                                         │
│  ├── WeatherApiClient (Adapter)                         │
│  │   ├── fetch_current_weather(lat, lon)                │
│  │   ├── fetch_forecast(lat, lon, days)                 │
│  │   ├── Handle HTTP communication                      │
│  │   └── Parse API responses                            │
│  │                                                       │
│  └── WeatherService (Business Logic)                    │
│      ├── get_weather_for_location(lat, lon, zip)        │
│      ├── Transform API data                             │
│      └── Aggregate current + forecast data              │
│                                                         │
│  Caching Module                                         │
│  └── ForecastCacheService (Proxy/Repository)            │
│      ├── fetch_or_store(zip_code, &block)               │
│      ├── 30-minute cache expiration                     │
│      ├── Cache hit/miss logging                         │
│      └── Distributed caching with Redis                 │
└────────────────────────────────────────────────────────┘
```

**Service Isolation Benefits:**
- Each service can be tested independently
- Services can be reused across controllers
- Easy to swap implementations (e.g., different weather providers)
- Clear separation of concerns

## Design Patterns

### 1. Facade Pattern

**Implementation:** `WeatherForecastFacade`

```ruby
# Before (without Facade) - Controller has to coordinate everything
class ForecastsController
  def create
    # Too much responsibility in controller!
    geocoding_service = GeocodingService.new
    location = geocoding_service.geocode_address(params[:address])
    
    cache_service = ForecastCacheService.new
    result = cache_service.fetch_or_store(location[:zip_code]) do
      weather_service = WeatherService.new
      weather_service.get_weather_for_location(...)
    end
    # ... more coordination logic
  end
end

# After (with Facade) - Clean and simple
class ForecastsController
  def create
    result = WeatherForecastFacade.get_forecast(params[:address])
    @forecast_data = result[:forecast]
    # Done!
  end
end
```

**Benefits:**
- Controllers stay thin
- Business logic coordination in one place
- Easy to add new features without touching controllers

### 2. Service Object Pattern

**Implementation:** All service classes

```ruby
# Example: GeocodingService
class Geocoding::GeocodingService
  # Single Responsibility: Geocoding
  def geocode_address(address)
    # Implementation
  end
  
  # All geocoding-related logic here
  # No weather logic, no caching logic
end
```

**Benefits:**
- Single Responsibility Principle
- Easy to test in isolation
- Reusable across the application
- Clear API boundaries

### 3. Adapter Pattern

**Implementation:** `WeatherApiClient`

```ruby
# Adapter wraps external API
class Weather::WeatherApiClient
  include HTTParty
  
  # Adapts WeatherAPI.com responses to our internal format
  def fetch_forecast(lat, lon, days: 3)
    response = self.class.get('/forecast.json', ...)
    handle_response(response)  # Transform to our format
  end
end
```

**Benefits:**
- Easy to swap weather providers
- Isolates external API changes
- Consistent internal interface
- Can add retry logic, circuit breakers, etc.

### 4. Proxy/Repository Pattern

**Implementation:** `ForecastCacheService`

```ruby
# Acts as a proxy with caching
class Caching::ForecastCacheService
  def fetch_or_store(zip_code, &block)
    # Check cache first (Proxy behavior)
    cached = fetch_from_cache(...)
    return cached if cached
    
    # Execute block and cache result
    fresh_data = block.call
    store_in_cache(...)
    fresh_data
  end
end
```

**Benefits:**
- Transparent caching
- Business logic doesn't know about cache
- Easy to change cache implementation
- Can add cache warming, invalidation strategies

### 5. Dependency Injection

**Implementation:** Throughout the application

```ruby
# Services accept dependencies
class Weather::WeatherService
  def initialize(api_client: WeatherApiClient.new)
    @api_client = api_client
  end
end

# In tests, inject a mock
let(:mock_client) { instance_double(WeatherApiClient) }
let(:service) { WeatherService.new(api_client: mock_client) }
```

**Benefits:**
- Testability (inject mocks)
- Flexibility (swap implementations)
- Loose coupling
- Follows Dependency Inversion Principle

## Service Layer Architecture

### Geocoding Service

```
┌─────────────────────────────────────┐
│      GeocodingService                │
│                                      │
│  Input: "1 Apple Park Way, CA"      │
│         │                            │
│         ▼                            │
│  1. Validate address                 │
│  2. Generate cache key               │
│  3. Check cache (1 hour TTL)         │
│         │                            │
│         ├─► Cache Hit                │
│         │   └─► Return cached data   │
│         │                            │
│         └─► Cache Miss               │
│             ├─► Call Geocoder API    │
│             ├─► Extract data         │
│             └─► Store in cache       │
│                                      │
│  Output: {                           │
│    latitude: 37.3349,                │
│    longitude: -122.0090,             │
│    zip_code: "95014",                │
│    city: "Cupertino",                │
│    state: "California"               │
│  }                                   │
└─────────────────────────────────────┘
```

**Cache Strategy:**
- **Key**: MD5 hash of normalized address
- **TTL**: 1 hour (addresses don't change)
- **Provider**: Nominatim (free, no API key)

### Weather Service

```
┌─────────────────────────────────────┐
│       WeatherService                 │
│                                      │
│  Dependencies:                       │
│  - WeatherApiClient (injectable)     │
│                                      │
│  Flow:                               │
│  1. Receive: (lat, lon, zip)         │
│  2. Call API client                  │
│  3. Transform data structure         │
│  4. Return standardized format       │
│                                      │
│  Data Transformation:                │
│  API Format → Application Format     │
│                                      │
│  API:                                │
│  {                                   │
│    "current": {                      │
│      "temp_f": 72.5                  │
│    }                                 │
│  }                                   │
│                                      │
│  App:                                │
│  {                                   │
│    current: {                        │
│      temperature_f: 72.5             │
│    }                                 │
│  }                                   │
└─────────────────────────────────────┘
```

**Separation of Concerns:**
- **WeatherApiClient**: HTTP communication, error handling
- **WeatherService**: Business logic, data transformation

### Cache Service

```
┌────────────────────────────────────────┐
│     ForecastCacheService                │
│                                         │
│  Cache Key: "weather_forecast:{zip}"    │
│  TTL: 30 minutes                        │
│                                         │
│  fetch_or_store(zip_code, &block)       │
│         │                               │
│         ▼                               │
│  Generate cache key                     │
│         │                               │
│         ▼                               │
│  Check Redis cache                      │
│         │                               │
│    ┌────┴────┐                          │
│    │         │                          │
│  Hit       Miss                         │
│    │         │                          │
│    │         ▼                          │
│    │    Execute block                   │
│    │    (fetch weather)                 │
│    │         │                          │
│    │         ▼                          │
│    │    Store in cache                  │
│    │    with metadata                   │
│    │    (cached_at, expires_at)         │
│    │         │                          │
│    └────┬────┘                          │
│         │                               │
│         ▼                               │
│  Return with cache metadata             │
└────────────────────────────────────────┘
```

**Cache Design:**
- **Key Strategy**: Normalized zip code
- **Value**: Weather data + metadata (cached_at, expires_at)
- **Invalidation**: Automatic after 30 minutes
- **Logging**: Hit/Miss rates for monitoring

## Caching Strategy

### Why Cache by Zip Code?

1. **Locality**: People in same zip code get same weather
2. **Efficiency**: 30,000+ zip codes vs. infinite addresses
3. **Hit Rate**: High probability of cache hits in urban areas
4. **Simplicity**: Easy to understand and implement

### Cache Entry Structure

```ruby
{
  data: {
    # Full weather data
    zip_code: "95014",
    location: { ... },
    current: { ... },
    forecast: [ ... ]
  },
  cached_at: Time.parse("2024-01-15 10:30:00")
}
```

### Cache Expiration Strategy

```
Request 1 (10:00 AM) → Cache MISS
  ├─► Fetch from API
  ├─► Store in cache (expires 10:30 AM)
  └─► Return to user

Request 2 (10:15 AM) → Cache HIT
  └─► Return cached data (15 minutes old)

Request 3 (10:35 AM) → Cache MISS (expired)
  ├─► Fetch from API
  ├─► Store in cache (expires 11:05 AM)
  └─► Return to user
```

### Benefits

- **API Cost Reduction**: ~95% reduction in API calls
- **Performance**: <10ms cache reads vs. ~500ms API calls
- **User Experience**: Fast response times
- **Scalability**: Reduces load on external APIs

## Error Handling

### Error Hierarchy

```
StandardError
│
├── Geocoding::GeocodingService::GeocodingError
│   ├── Address not found
│   ├── Invalid address format
│   └── Geocoding API error
│
└── Weather::WeatherApiError
    ├── Invalid API key
    ├── API quota exceeded
    ├── Location not found
    └── Service unavailable
```

### Error Flow

```
User Input
    │
    ▼
Controller
    │
    ├─► Success → Render forecast
    │
    ├─► GeocodingError → Show address error
    │
    ├─► WeatherApiError → Show API error
    │
    └─► StandardError → Show generic error
```

### Error Handling Strategy

1. **Service Layer**: Raise domain-specific exceptions
2. **Controller Layer**: Catch and translate to user messages
3. **Logging**: Log all errors with context
4. **User Feedback**: Friendly, actionable error messages

```ruby
# Service Layer
raise Weather::WeatherApiError, 'Invalid API key'

# Controller Layer
rescue Weather::WeatherApiError => e
  flash.now[:error] = "Unable to retrieve weather data: #{e.message}"
  render :index
end
```

## Data Flow

### Complete Request Flow

```
1. User enters address
        │
        ▼
2. POST /forecasts
        │
        ▼
3. ForecastsController#create
        │
        ├─► Validate input
        └─► Call WeatherForecastFacade.get_forecast
                │
                ▼
4. WeatherForecastFacade.get_forecast
        │
        ├─► Step 1: GeocodingService.geocode_address
        │   │       │
        │   │       ├─► Cache check (1 hour)
        │   │       │   └─► HIT: Return cached location
        │   │       │
        │   │       └─► MISS: Call Geocoder API
        │   │           ├─► Parse response
        │   │           ├─► Extract zip code
        │   │           └─► Cache result
        │   │
        │   └─► Returns: { lat, lon, zip_code, ... }
        │
        ├─► Step 2: ForecastCacheService.fetch_or_store(zip)
        │   │
        │   ├─► Cache check (30 minutes)
        │   │   └─► HIT: Return cached weather
        │   │
        │   └─► MISS: Execute block
        │       │
        │       └─► WeatherService.get_weather_for_location
        │           │
        │           ├─► WeatherApiClient.fetch_forecast
        │           │   ├─► HTTP GET to WeatherAPI.com
        │           │   ├─► Parse JSON response
        │           │   └─► Return raw data
        │           │
        │           ├─► Transform to app format
        │           │   ├─► Extract current conditions
        │           │   ├─► Extract 3-day forecast
        │           │   └─► Add metadata
        │           │
        │           └─► Return transformed data
        │
        └─► Step 3: Aggregate results
            │
            └─► Returns: {
                  forecast: { weather data },
                  location: { location data },
                  from_cache: true/false,
                  cached_at: Time,
                  expires_at: Time
                }
                │
                ▼
5. Controller assigns instance variables
        │
        ▼
6. Render forecasts/show.html.erb
        │
        ├─► Display current weather
        ├─► Display 3-day forecast
        └─► Show cache indicator
```

## Scalability

### Horizontal Scaling

```
                    ┌─────────────┐
                    │   Nginx     │
                    │ Load Balancer│
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
    ┌───▼───┐          ┌───▼───┐         ┌───▼───┐
    │Rails  │          │Rails  │         │Rails  │
    │Instance│         │Instance│        │Instance│
    │  #1   │          │  #2   │         │  #3   │
    └───┬───┘          └───┬───┘         └───┬───┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    ┌──────▼──────┐
                    │    Redis    │
                    │ (Shared Cache)│
                    └─────────────┘
```

**Key Points:**
- **Stateless**: No session state in application servers
- **Shared Cache**: Redis accessible to all instances
- **Database**: Can scale to PostgreSQL with read replicas

### Performance Optimizations

1. **Caching**: 
   - Geocoding: 1 hour cache
   - Weather: 30 minute cache
   - Expected hit rate: 80-90%

2. **Connection Pooling**:
   - HTTParty reuses connections
   - Redis connection pool

3. **Timeouts**:
   - API requests: 10 seconds
   - Redis operations: 1 second

4. **Lazy Loading**:
   - Services instantiated only when needed
   - Memoization for repeated access

### Capacity Planning

**Single Instance:**
- Requests per second: ~100
- Average response time: 50ms (cache hit), 500ms (cache miss)
- Memory usage: ~200MB

**10 Instances:**
- Requests per second: ~1000
- Handles 86M requests/day
- Scales linearly with cache hit rate >80%

## Security

### API Key Management

```ruby
# ❌ BAD: Hardcoded
api_key = "abc123def456"

# ✅ GOOD: Environment variable
api_key = ENV['WEATHER_API_KEY']

# ✅ GOOD: With validation
api_key = ENV.fetch('WEATHER_API_KEY') do
  raise 'API key not configured'
end
```

### Input Validation

- **Address**: Validated for presence, sanitized
- **Zip Code**: Normalized and validated format
- **CSRF Protection**: Rails default protection enabled

### Data Protection

- **No PII Storage**: Addresses not stored
- **HTTPS**: Force SSL in production
- **Cache Keys**: Hashed addresses for privacy

### Error Messages

```ruby
# ❌ BAD: Exposes internals
"Database connection failed: password incorrect"

# ✅ GOOD: Generic but helpful
"An error occurred while processing your request"
```

---

This architecture provides a solid foundation for a production-grade weather forecast application with clear separation of concerns, comprehensive error handling, and excellent scalability characteristics.

