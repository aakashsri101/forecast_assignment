# Quick Start Guide

Get the Weather Forecast Application running in 5 minutes!

## Prerequisites

- Ruby 3.3.1
- Redis
- Git

## Installation

```bash
# 1. Clone repository
git clone <your-github-url>
cd weather-forecast-app

# 2. Install dependencies
bundle install

# 3. Get API key from https://www.weatherapi.com/signup.aspx
# Then create .env file:
echo "WEATHER_API_KEY=your_api_key_here" > .env
echo "REDIS_URL=redis://localhost:6379/1" >> .env

# 4. Start Redis
redis-server &

# 5. Setup database
rails db:create db:migrate

# 6. Run tests (optional but recommended)
bundle exec rspec

# 7. Start server
rails server
```

## Access Application

Open browser: http://localhost:3000

## Test It Out

1. Enter address: "1 Apple Park Way, Cupertino, CA 95014"
2. Click "Get Forecast"
3. See current weather and 3-day forecast
4. Notice "Fresh Data" indicator
5. Search same address again
6. Notice "From Cache" indicator

## Troubleshooting

### Redis Not Running
```bash
redis-cli ping  # Should return "PONG"
brew services start redis  # macOS
sudo systemctl start redis-server  # Linux
```

### API Key Error
```bash
# Verify API key is set
cat .env | grep WEATHER_API_KEY

# Get new key at:
# https://www.weatherapi.com/signup.aspx
```

### Port Already in Use
```bash
# Use different port
rails server -p 3001
```

## Next Steps

- Read [README.md](README.md) for full documentation
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Review [TESTING.md](TESTING.md) for testing guide
- Explore the code in `app/services/`

## Support

For issues, see [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed troubleshooting.

---

Enjoy using the Weather Forecast Application! 🌤️

