# Environment Variables Example

Create a `.env` file in the root directory with the following variables:

```
# Weather API Configuration
# Get your free API key from: https://www.weatherapi.com/signup.aspx
WEATHER_API_KEY=your_weather_api_key_here
WEATHER_API_BASE_URL=https://api.weatherapi.com/v1

# Redis Configuration
REDIS_URL=redis://localhost:6379/1

# Rails Configuration
RAILS_ENV=development
RAILS_LOG_LEVEL=debug

# Cache Configuration
CACHE_EXPIRATION_MINUTES=30
```

## Getting a Weather API Key

1. Visit https://www.weatherapi.com/signup.aspx
2. Sign up for a free account
3. Copy your API key from the dashboard
4. Paste it into your `.env` file

