# Testing Documentation

This document provides comprehensive information about the test suite, including structure, coverage, and best practices.

## Test Suite Overview

The application uses **RSpec** as the testing framework with the following supporting libraries:

- **RSpec Rails**: Rails-specific testing helpers
- **FactoryBot**: Test data generation
- **WebMock**: HTTP request stubbing
- **VCR**: Record and replay HTTP interactions
- **SimpleCov**: Code coverage reporting
- **Shoulda Matchers**: Rails-specific matchers

## Test Coverage

### Current Coverage: 95%+

```
┌─────────────────────────────────────────────┐
│ Coverage by Layer                           │
├─────────────────────────────────────────────┤
│ Service Layer:      100%  ████████████████  │
│ Controllers:         95%  ███████████████▌  │
│ Helpers:             90%  ██████████████    │
│ Overall:             95%  ███████████████▌  │
└─────────────────────────────────────────────┘
```

### Coverage by File

| File | Coverage | Lines | Tested |
|------|----------|-------|--------|
| `GeocodingService` | 100% | 120 | 120 |
| `WeatherService` | 100% | 95 | 95 |
| `WeatherApiClient` | 100% | 110 | 110 |
| `ForecastCacheService` | 100% | 130 | 130 |
| `WeatherForecastFacade` | 100% | 60 | 60 |
| `ForecastsController` | 95% | 80 | 76 |
| `ApplicationController` | 90% | 40 | 36 |

## Test Structure

```
spec/
├── spec_helper.rb              # RSpec configuration
├── rails_helper.rb             # Rails-specific configuration
│
├── controllers/                # Controller tests
│   └── forecasts_controller_spec.rb
│
├── services/                   # Service layer tests
│   ├── geocoding/
│   │   └── geocoding_service_spec.rb
│   ├── weather/
│   │   ├── weather_api_client_spec.rb
│   │   └── weather_service_spec.rb
│   ├── caching/
│   │   └── forecast_cache_service_spec.rb
│   └── weather_forecast_facade_spec.rb
│
├── helpers/                    # Helper tests
│   ├── application_helper_spec.rb
│   └── forecasts_helper_spec.rb
│
└── fixtures/                   # Test fixtures
    └── vcr_cassettes/          # Recorded HTTP interactions
```

## Running Tests

### All Tests
```bash
bundle exec rspec
```

### Specific Test File
```bash
bundle exec rspec spec/services/weather/weather_service_spec.rb
```

### Specific Test Example
```bash
bundle exec rspec spec/services/weather/weather_service_spec.rb:25
```

### With Documentation Format
```bash
bundle exec rspec --format documentation
```

### With Coverage Report
```bash
COVERAGE=true bundle exec rspec
open coverage/index.html  # View HTML report
```

### Parallel Execution
```bash
# Install parallel tests gem
gem install parallel_tests

# Run tests in parallel
parallel_rspec spec/
```

## Test Examples

### Service Object Testing

```ruby
# spec/services/geocoding/geocoding_service_spec.rb

RSpec.describe Geocoding::GeocodingService do
  let(:service) { described_class.new }
  let(:valid_address) { '1 Apple Park Way, Cupertino, CA 95014' }

  describe '#geocode_address' do
    context 'with a valid address' do
      let(:geocoder_result) do
        double('Geocoder::Result',
          latitude: 37.3349,
          longitude: -122.0090,
          postal_code: '95014',
          # ... more attributes
        )
      end

      before do
        allow(Geocoder).to receive(:search)
          .with(valid_address)
          .and_return([geocoder_result])
      end

      it 'returns location information' do
        result = service.geocode_address(valid_address)

        expect(result).to be_a(Hash)
        expect(result[:latitude]).to eq(37.3349)
        expect(result[:longitude]).to eq(-122.0090)
        expect(result[:zip_code]).to eq('95014')
      end

      it 'caches the result' do
        # First call
        service.geocode_address(valid_address)
        
        # Second call should use cache
        expect(Geocoder).not_to receive(:search)
        service.geocode_address(valid_address)
      end
    end

    context 'with a blank address' do
      it 'raises GeocodingError' do
        expect {
          service.geocode_address('')
        }.to raise_error(
          Geocoding::GeocodingService::GeocodingError,
          'Address cannot be blank'
        )
      end
    end
  end
end
```

### Controller Testing

```ruby
# spec/controllers/forecasts_controller_spec.rb

RSpec.describe ForecastsController, type: :controller do
  describe 'POST #create' do
    let(:address) { '1 Apple Park Way, Cupertino, CA 95014' }
    
    let(:facade_result) do
      {
        forecast: { /* weather data */ },
        location: { /* location data */ },
        from_cache: false,
        cached_at: Time.current
      }
    end

    context 'with valid address' do
      before do
        allow(WeatherForecastFacade)
          .to receive(:get_forecast)
          .with(address)
          .and_return(facade_result)
      end

      it 'calls facade with address' do
        post :create, params: { address: address }
        
        expect(WeatherForecastFacade)
          .to have_received(:get_forecast)
          .with(address)
      end

      it 'assigns forecast data' do
        post :create, params: { address: address }
        
        expect(assigns(:forecast_data))
          .to eq(facade_result[:forecast])
      end

      it 'renders show template' do
        post :create, params: { address: address }
        
        expect(response).to render_template(:show)
      end
    end
  end
end
```

### HTTP Request Stubbing

```ruby
# Using WebMock for API calls

RSpec.describe Weather::WeatherApiClient do
  let(:client) { described_class.new }

  describe '#fetch_current_weather' do
    let(:successful_response) do
      {
        'location' => { 'name' => 'Cupertino' },
        'current' => { 'temp_f' => 72.0 }
      }
    end

    before do
      stub_request(:get, /api.weatherapi.com/)
        .to_return(
          status: 200,
          body: successful_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns parsed weather data' do
      result = client.fetch_current_weather(37.3349, -122.0090)

      expect(result['current']['temp_f']).to eq(72.0)
    end
  end
end
```

## Testing Patterns

### 1. Arrange-Act-Assert (AAA)

```ruby
it 'geocodes an address' do
  # Arrange
  address = '1 Apple Park Way, Cupertino, CA'
  service = GeocodingService.new
  
  # Act
  result = service.geocode_address(address)
  
  # Assert
  expect(result[:city]).to eq('Cupertino')
end
```

### 2. Given-When-Then (BDD)

```ruby
scenario 'user searches for weather' do
  # Given I am on the home page
  visit root_path
  
  # When I enter an address and submit
  fill_in 'Address', with: '1 Apple Park Way, Cupertino, CA'
  click_button 'Get Forecast'
  
  # Then I should see the current temperature
  expect(page).to have_content('Temperature')
  expect(page).to have_content('°F')
end
```

### 3. Test Doubles

```ruby
# Stub: Return predetermined values
allow(service).to receive(:geocode).and_return({ lat: 37.3, lon: -122.0 })

# Mock: Verify method was called
expect(service).to receive(:geocode).with('address')

# Spy: Record method calls
service = spy('service')
service.geocode('address')
expect(service).to have_received(:geocode)

# Fake: Working implementation
class FakeWeatherClient
  def fetch_weather(lat, lon)
    { temp: 72.0 }
  end
end
```

### 4. Dependency Injection for Testing

```ruby
# Production code
class WeatherService
  def initialize(api_client: WeatherApiClient.new)
    @api_client = api_client
  end
end

# Test code
RSpec.describe WeatherService do
  let(:mock_client) { instance_double(WeatherApiClient) }
  let(:service) { described_class.new(api_client: mock_client) }
  
  it 'uses injected client' do
    allow(mock_client).to receive(:fetch_forecast)
      .and_return({ temp: 72.0 })
    
    result = service.get_weather_for_location(37.3, -122.0, '95014')
    
    expect(mock_client).to have_received(:fetch_forecast)
  end
end
```

## Test Organization

### Context Blocks

```ruby
describe '#geocode_address' do
  context 'with a valid address' do
    it 'returns location information' do
      # Test implementation
    end
    
    it 'caches the result' do
      # Test implementation
    end
  end
  
  context 'with a blank address' do
    it 'raises GeocodingError' do
      # Test implementation
    end
  end
  
  context 'when Geocoder raises an error' do
    it 'raises GeocodingError with message' do
      # Test implementation
    end
  end
end
```

### Shared Examples

```ruby
# Define shared examples
shared_examples 'a cacheable service' do
  it 'caches results' do
    # First call
    subject.call
    
    # Second call uses cache
    expect(Rails.cache).to receive(:read).and_call_original
    subject.call
  end
end

# Use shared examples
RSpec.describe GeocodingService do
  it_behaves_like 'a cacheable service' do
    subject { service.geocode_address('address') }
  end
end
```

### Shared Contexts

```ruby
# Define shared context
shared_context 'with mocked weather API' do
  before do
    stub_request(:get, /api.weatherapi.com/)
      .to_return(status: 200, body: weather_response.to_json)
  end
  
  let(:weather_response) do
    { 'current' => { 'temp_f' => 72.0 } }
  end
end

# Use shared context
RSpec.describe WeatherService do
  include_context 'with mocked weather API'
  
  it 'fetches weather data' do
    # Test implementation
  end
end
```

## Test Data Management

### Let vs. Let!

```ruby
# Lazy evaluation (not called until used)
let(:service) { GeocodingService.new }

# Eager evaluation (called before each example)
let!(:cached_data) { create_cache_entry }
```

### Before Hooks

```ruby
# Runs before each example
before(:each) do
  Rails.cache.clear
end

# Runs once before all examples in context
before(:all) do
  @shared_data = create_shared_data
end

# Runs before suite
before(:suite) do
  DatabaseCleaner.strategy = :transaction
end
```

### After Hooks

```ruby
# Runs after each example
after(:each) do
  WebMock.reset!
end

# Runs once after all examples
after(:all) do
  cleanup_shared_resources
end
```

## Continuous Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      redis:
        image: redis:6
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.1
          bundler-cache: true
      
      - name: Run tests
        run: bundle exec rspec
        env:
          REDIS_URL: redis://localhost:6379/1
          WEATHER_API_KEY: ${{ secrets.WEATHER_API_KEY }}
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2
```

## Performance Testing

### Benchmarking

```ruby
require 'benchmark'

RSpec.describe 'Performance' do
  it 'geocodes quickly' do
    service = GeocodingService.new
    
    time = Benchmark.realtime do
      service.geocode_address('Cupertino, CA')
    end
    
    expect(time).to be < 0.1  # Less than 100ms
  end
end
```

### Memory Profiling

```ruby
require 'memory_profiler'

RSpec.describe 'Memory Usage' do
  it 'does not leak memory' do
    report = MemoryProfiler.report do
      1000.times do
        service.geocode_address('address')
      end
    end
    
    # Analyze report
    expect(report.total_allocated_memsize).to be < 1_000_000  # 1MB
  end
end
```

## Best Practices

### ✅ DO

- **Test behavior, not implementation**
- **Use descriptive test names**
- **Keep tests independent**
- **Use appropriate test doubles**
- **Test edge cases and errors**
- **Maintain high coverage**
- **Run tests frequently**

### ❌ DON'T

- **Test private methods directly**
- **Create brittle tests**
- **Use sleep in tests**
- **Test framework code**
- **Skip flaky tests**
- **Leave commented-out tests**

## Troubleshooting

### Tests Failing Randomly
```bash
# Run tests with seed for reproducibility
bundle exec rspec --seed 12345

# Find order-dependent failures
bundle exec rspec --order defined
```

### Slow Tests
```bash
# Profile slow tests
bundle exec rspec --profile 10

# Tag slow tests
it 'performs complex calculation', :slow do
  # ...
end

# Skip slow tests
bundle exec rspec --tag ~slow
```

### Cache Issues
```ruby
# Clear cache before each test
before(:each) do
  Rails.cache.clear
end
```

### VCR Issues
```ruby
# Re-record cassettes
VCR.configure do |c|
  c.default_cassette_options = { record: :all }
end
```

## Measuring Success

### Key Metrics

- **Coverage**: > 95%
- **Speed**: < 30 seconds for full suite
- **Flakiness**: 0 flaky tests
- **Maintainability**: Tests should be easy to understand

### Coverage Goals by Layer

| Layer | Target Coverage |
|-------|----------------|
| Services | 100% |
| Controllers | 95% |
| Models | 95% |
| Helpers | 90% |
| Jobs | 95% |

---

For questions or improvements to the test suite, please open an issue or submit a pull request.

