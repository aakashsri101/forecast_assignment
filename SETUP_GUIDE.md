# Complete Setup Guide

This guide will walk you through setting up the Weather Forecast Application from scratch.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

| Software | Version | Installation Check |
|----------|---------|-------------------|
| Ruby | 3.3.1+ | `ruby -v` |
| Rails | 7.1.0+ | `rails -v` |
| Bundler | 2.4.0+ | `bundler -v` |
| Redis | 6.0+ | `redis-cli --version` |
| Git | 2.30+ | `git --version` |

## Installation Steps

### 1. Install Ruby (if not installed)

#### macOS (using rbenv)
```bash
# Install rbenv
brew install rbenv ruby-build

# Initialize rbenv
rbenv init

# Install Ruby 3.3.1
rbenv install 3.3.1

# Set as default
rbenv global 3.3.1

# Verify
ruby -v  # Should show ruby 3.3.1
```

#### Ubuntu/Debian
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y git-core curl zlib1g-dev build-essential \
  libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common \
  libffi-dev

# Install rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

# Install ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby
rbenv install 3.3.1
rbenv global 3.3.1
```

### 2. Install Redis

#### macOS
```bash
# Install Redis
brew install redis

# Start Redis
brew services start redis

# Verify Redis is running
redis-cli ping  # Should return "PONG"
```

#### Ubuntu/Debian
```bash
# Install Redis
sudo apt-get update
sudo apt-get install redis-server

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify Redis is running
redis-cli ping  # Should return "PONG"
```

### 3. Clone the Repository

```bash
# Clone the repository
git clone <your-github-repo-url>

# Navigate to the project directory
cd weather-forecast-app

# Verify you're in the right directory
ls -la  # Should see Gemfile, README.md, etc.
```

### 4. Install Dependencies

```bash
# Install Bundler if not installed
gem install bundler

# Install project dependencies
bundle install
```

**Expected Output:**
```
Fetching gem metadata from https://rubygems.org/
Resolving dependencies...
Installing rails 7.1.0
Installing httparty 0.21.0
...
Bundle complete! 25 Gemfile dependencies, 95 gems now installed.
```

### 5. Configure Environment Variables

```bash
# Copy the example environment file
cp ENV_EXAMPLE.md .env

# Edit the .env file
nano .env  # or use your preferred editor
```

**Required Environment Variables:**
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

### 6. Get Weather API Key

1. **Visit WeatherAPI.com:**
   - Go to: https://www.weatherapi.com/signup.aspx

2. **Sign Up:**
   - Create a free account
   - Verify your email

3. **Get API Key:**
   - Login to your dashboard
   - Copy your API key
   - It should look like: `abc123def456...`

4. **Add to .env:**
   ```bash
   WEATHER_API_KEY=abc123def456...
   ```

### 7. Setup Database

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed database (if needed)
rails db:seed
```

**Expected Output:**
```
Created database 'db/development.sqlite3'
Created database 'db/test.sqlite3'
```

### 8. Verify Installation

```bash
# Check Rails version
rails -v
# Expected: Rails 7.1.0

# Check Ruby version
ruby -v
# Expected: ruby 3.3.1

# Check Bundler
bundle -v
# Expected: Bundler version 2.4.x

# Check Redis
redis-cli ping
# Expected: PONG

# Verify environment variables
rails runner 'puts ENV["WEATHER_API_KEY"]'
# Expected: Your API key
```

### 9. Run Tests

```bash
# Run all tests
bundle exec rspec

# Expected output should show all tests passing
# Example:
# .................................
# 95 examples, 0 failures
```

### 10. Start the Application

```bash
# Start Redis (if not running)
redis-server

# In a new terminal, start Rails server
rails server

# Or use a specific port
rails server -p 3000
```

**Expected Output:**
```
=> Booting Puma
=> Rails 7.1.0 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

### 11. Access the Application

Open your browser and navigate to:
```
http://localhost:3000
```

You should see the Weather Forecast application homepage.

## Verification Checklist

- [ ] Ruby 3.3.1 installed and verified
- [ ] Redis installed and running
- [ ] Repository cloned successfully
- [ ] All gems installed (`bundle install`)
- [ ] `.env` file created with API key
- [ ] Database created and migrated
- [ ] All tests passing (`bundle exec rspec`)
- [ ] Rails server starts successfully
- [ ] Application accessible at http://localhost:3000
- [ ] Can search for weather and see results

## Testing the Application

### 1. Test Basic Functionality

```bash
# Visit homepage
open http://localhost:3000

# Enter an address
# Example: "1 Apple Park Way, Cupertino, CA 95014"

# Click "Get Forecast"

# You should see:
# - Current temperature
# - 3-day forecast
# - Cache indicator (Fresh Data)
```

### 2. Test Caching

```bash
# Search for the same address again immediately

# You should see:
# - Same weather data
# - Cache indicator showing "From Cache"
# - Timestamp of when data was cached
```

### 3. Test Error Handling

```bash
# Try an invalid address
# Example: "xyzabc123invalid"

# You should see:
# - Error message
# - Ability to try again
```

## Troubleshooting

### Issue: Redis Connection Error

**Error:**
```
Redis::CannotConnectError (Error connecting to Redis)
```

**Solution:**
```bash
# Check if Redis is running
redis-cli ping

# If not running, start it
brew services start redis  # macOS
sudo systemctl start redis-server  # Linux
```

### Issue: Bundle Install Fails

**Error:**
```
An error occurred while installing nokogiri
```

**Solution (macOS):**
```bash
# Install dependencies
brew install libxml2

# Reinstall
bundle install
```

**Solution (Ubuntu):**
```bash
# Install dependencies
sudo apt-get install libxml2-dev libxslt-dev

# Reinstall
bundle install
```

### Issue: Weather API Error

**Error:**
```
Weather API key not configured
```

**Solution:**
```bash
# Verify .env file exists
cat .env

# Verify API key is set
rails runner 'puts ENV["WEATHER_API_KEY"]'

# If blank, add your API key to .env
echo "WEATHER_API_KEY=your_actual_key" >> .env

# Restart Rails server
```

### Issue: Port Already in Use

**Error:**
```
Address already in use - bind(2) (Errno::EADDRINUSE)
```

**Solution:**
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use a different port
rails server -p 3001
```

### Issue: Database Migration Error

**Error:**
```
ActiveRecord::PendingMigrationError
```

**Solution:**
```bash
# Run migrations
rails db:migrate

# If that fails, reset database
rails db:reset
```

## Development Tools

### Recommended Tools

1. **Text Editor/IDE:**
   - VS Code with Ruby extensions
   - RubyMine
   - Sublime Text

2. **Terminal:**
   - iTerm2 (macOS)
   - Terminator (Linux)

3. **API Testing:**
   - Postman
   - Insomnia
   - curl

4. **Redis GUI:**
   - RedisInsight
   - Medis (macOS)

### Useful Commands

```bash
# Rails console
rails console

# Check routes
rails routes

# Database console
rails dbconsole

# Clear cache
rails runner "Rails.cache.clear"

# Check code style
rubocop

# View logs
tail -f log/development.log
```

## Next Steps

1. **Read the Documentation:**
   - [README.md](README.md) - Overview and features
   - [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
   - [TESTING.md](TESTING.md) - Testing guide

2. **Explore the Code:**
   - Check out the service layer in `app/services/`
   - Review the tests in `spec/`
   - Understand the controllers in `app/controllers/`

3. **Make Changes:**
   - Try modifying the UI
   - Add new features
   - Write additional tests

4. **Deploy:**
   - See deployment guides for Heroku, AWS, etc.

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [README.md](README.md) troubleshooting section
2. Review the logs: `tail -f log/development.log`
3. Search for existing issues on GitHub
4. Create a new issue with:
   - Error message
   - Steps to reproduce
   - Your environment (OS, Ruby version, etc.)

## Quick Reference

```bash
# Start everything
redis-server &                    # Start Redis in background
rails server                       # Start Rails

# Run tests
bundle exec rspec                  # All tests
bundle exec rspec spec/services/  # Service tests only

# Database commands
rails db:create                    # Create database
rails db:migrate                   # Run migrations
rails db:reset                     # Reset database

# Cache commands
rails runner "Rails.cache.clear"  # Clear cache

# Code quality
rubocop                           # Check code style
```

---

You're all set! 🎉 The application should now be running at http://localhost:3000

