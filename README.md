# Weather Forecast Application 🌤️

A production-grade Ruby on Rails application that provides weather forecasts for any address with intelligent caching and a beautiful user interface.

[![Ruby Version](https://img.shields.io/badge/ruby-3.3.1-red.svg)](https://www.ruby-lang.org/)
[![Rails Version](https://img.shields.io/badge/rails-7.1.0-red.svg)](https://rubyonrails.org/)
[![RSpec](https://img.shields.io/badge/tested%20with-RSpec-green.svg)](https://rspec.info/)
[![Code Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen.svg)](https://github.com/simplecov-ruby/simplecov)

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Design Patterns](#design-patterns)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Running Tests](#running-tests)
- [API Documentation](#api-documentation)

## ✨ Features

### Core Requirements
- ✅ **Address Input**: Accept any address as input
- ✅ **Current Temperature**: Real-time current weather conditions
- ✅ **Extended Forecast**: 3-day forecast with high/low temperatures
- ✅ **Detailed Conditions**: Wind, humidity, pressure, UV index, and more
- ✅ **Intelligent Caching**: 30-minute cache per zip code with Redis
- ✅ **Cache Indicators**: Visual indication of cached vs. fresh data

### Additional Features
- 🎨 Beautiful, responsive UI with modern design
- 🔍 Comprehensive error handling and user feedback
- 📊 Detailed astronomical data (sunrise, sunset, moon phases)
- 🌡️ Multiple temperature units (Fahrenheit and Celsius)
- ⚡ Optimized performance with service layer architecture
- 🧪 Comprehensive test coverage (95%+)

## 🏗️ Architecture

This application follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Controllers  │  │    Views     │  │   Helpers    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │         WeatherForecastFacade (Orchestrator)     │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Service Layer                         │
│  ┌────────────────┐  ┌────────────┐  ┌─────────────┐   │
│  │    Geocoding   │  │  Weather   │  │   Caching   │   │
│  │    Service     │  │  Service   │  │   Service   │   │
│  └────────────────┘  └────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                    │
│  ┌────────────────┐  ┌────────────┐  ┌─────────────┐   │
│  │    Geocoder    │  │  Weather   │  │    Redis    │   │
│  │      Gem       │  │    API     │  │    Cache    │   │
│  └────────────────┘  └────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

#### **Presentation Layer**
- **Controllers**: Handle HTTP requests, coordinate services, manage responses
- **Views**: Render HTML with weather data, cache indicators, and user feedback
- **Helpers**: Provide view-specific formatting and utility methods

#### **Application Layer**
- **Facade**: Single entry point that orchestrates all business operations
- Coordinates between services
- Provides simplified interface to controllers

#### **Service Layer**
- **GeocodingService**: Address-to-coordinate conversion and zip code extraction
- **WeatherService**: Weather data retrieval and transformation
- **WeatherApiClient**: HTTP communication with weather API
- **ForecastCacheService**: Cache management with 30-minute expiration

#### **Infrastructure Layer**
- **Geocoder Gem**: External geocoding provider (Nominatim)
- **Weather API**: External weather data provider (WeatherAPI.com)
- **Redis Cache**: Distributed caching for horizontal scalability

## 🎨 Design Patterns

This application demonstrates multiple enterprise design patterns:

### 1. **Facade Pattern** (`WeatherForecastFacade`)
- **Purpose**: Simplifies complex subsystem interactions
- **Location**: `app/services/weather_forecast_facade.rb`
- **Benefits**: 
  - Single entry point for controllers
  - Hides complexity of service coordination
  - Easy to test and maintain

### 2. **Service Object Pattern** (All Services)
- **Purpose**: Encapsulates business logic away from models and controllers
- **Locations**: 
  - `app/services/geocoding/geocoding_service.rb`
  - `app/services/weather/weather_service.rb`
  - `app/services/caching/forecast_cache_service.rb`
- **Benefits**: 
  - Single Responsibility Principle
  - Testable in isolation
  - Reusable across application

### 3. **Adapter Pattern** (`WeatherApiClient`)
- **Purpose**: Wraps external API to provide consistent interface
- **Location**: `app/services/weather/weather_api_client.rb`
- **Benefits**: 
  - Easy to swap providers
  - Isolates external dependencies
  - Consistent error handling

### 4. **Proxy Pattern** (`ForecastCacheService`)
- **Purpose**: Provides caching layer transparently
- **Location**: `app/services/caching/forecast_cache_service.rb`
- **Benefits**: 
  - Transparent caching
  - Reduces API calls
  - Improves performance

### 5. **Repository Pattern** (`ForecastCacheService`)
- **Purpose**: Abstracts data storage from business logic
- **Benefits**: 
  - Clean separation of concerns
  - Easy to change cache implementation
  - Testable without Redis

### 6. **Template Method Pattern** (`ApplicationController`)
- **Purpose**: Provides base functionality for all controllers
- **Location**: `app/controllers/application_controller.rb`
- **Benefits**: 
  - DRY principle
  - Consistent error handling
  - Shared authentication/authorization hooks

### 7. **Dependency Injection**
- **Example**: Services accept dependencies in constructors
```ruby
WeatherService.new(api_client: custom_client)
```
- **Benefits**: 
  - Testability (inject mocks/stubs)
  - Flexibility (swap implementations)
  - Loose coupling

## 🔧 Prerequisites

- **Ruby**: 3.3.1 or higher
- **Rails**: 7.1.0 or higher
- **Redis**: 6.0 or higher (for caching)
- **Bundler**: 2.4.0 or higher
- **Git**: For version control

### System Dependencies (macOS)
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Redis
brew install redis

# Start Redis
brew services start redis
```

### System Dependencies (Ubuntu/Debian)
```bash
# Install Redis
sudo apt-get update
sudo apt-get install redis-server

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

## 📦 Installation

### 1. Clone the Repository
```bash
git clone <your-github-repo-url>
cd weather-forecast-app
```

### 2. Install Ruby Dependencies
```bash
bundle install
```

### 3. Setup Database
```bash
rails db:create
rails db:migrate
```

### 4. Configure Environment Variables
Create a `.env` file in the root directory:
```bash
# Weather API Configuration
WEATHER_API_KEY=your_api_key_here
WEATHER_API_BASE_URL=https://api.weatherapi.com/v1

# Redis Configuration
REDIS_URL=redis://localhost:6379/1

# Rails Configuration
RAILS_ENV=development
RAILS_LOG_LEVEL=debug

# Cache Configuration
CACHE_EXPIRATION_MINUTES=30
```

### 5. Get Weather API Key
1. Visit [WeatherAPI.com](https://www.weatherapi.com/signup.aspx)
2. Sign up for a free account
3. Copy your API key from the dashboard
4. Add it to your `.env` file

## 🚀 Running the Application

### Start Redis (if not running)
```bash
redis-server
```

### Start Rails Server
```bash
rails server
```

**Note:** Caching is automatically enabled in development mode. When the server starts, you'll see a message confirming Redis connection.

The application will be available at: **http://localhost:3000**

### Using Different Ports
```bash
rails server -p 3001
```

## 🧪 Running Tests

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test File
```bash
bundle exec rspec spec/services/weather/weather_service_spec.rb
```

### Run Tests with Coverage
```bash
COVERAGE=true bundle exec rspec
```

Coverage report will be generated in `coverage/index.html`

### Run Tests with Documentation Format
```bash
bundle exec rspec --format documentation
```

### Test Coverage Goals
- **Overall Coverage**: 95%+
- **Service Layer**: 100%
- **Controller Layer**: 95%+
- **Integration Tests**: Key user flows

