# Contributing to Weather Forecast Application

Thank you for your interest in contributing to the Weather Forecast Application! This document provides guidelines for contributions.

## Code of Conduct

- Be respectful and inclusive
- Follow Ruby style guidelines
- Write comprehensive tests
- Document your changes

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone <your-fork-url>`
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Run tests: `bundle exec rspec`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

## Development Process

### Before Starting

- Check existing issues and PRs
- Discuss major changes in an issue first
- Keep changes focused and atomic

### Code Standards

#### Ruby Style Guide

Follow the [Ruby Style Guide](https://rubystyle.guide/):

```ruby
# Good
def geocode_address(address)
  validate_address!(address)
  perform_geocoding(address)
end

# Bad
def geocodeAddress(addr)
  if addr.blank?
    raise "error"
  end
  geocode(addr)
end
```

#### Naming Conventions

```ruby
# Classes: PascalCase
class WeatherService
end

# Methods: snake_case
def fetch_weather_data
end

# Constants: SCREAMING_SNAKE_CASE
CACHE_EXPIRATION = 30.minutes

# Private methods: prefixed with private keyword
private

def internal_method
end
```

### Testing Requirements

All code must include tests:

```ruby
# Service tests
RSpec.describe MyService do
  describe '#my_method' do
    context 'with valid input' do
      it 'returns expected result' do
        # Test implementation
      end
    end
    
    context 'with invalid input' do
      it 'raises appropriate error' do
        # Test implementation
      end
    end
  end
end
```

**Coverage Requirements:**
- New features: 100% coverage
- Bug fixes: Test covering the bug
- Overall project: Maintain >95% coverage

### Documentation

#### Code Comments

```ruby
##
# Service for geocoding addresses to coordinates.
#
# Example:
#   service = GeocodingService.new
#   result = service.geocode_address("123 Main St")
#
class GeocodingService
  ##
  # Geocodes an address to geographic coordinates
  #
  # @param address [String] The address to geocode
  # @return [Hash] Location data including lat, lon, zip
  # @raise [GeocodingError] If address cannot be geocoded
  #
  def geocode_address(address)
    # Implementation
  end
end
```

#### README Updates

Update README.md for:
- New features
- Configuration changes
- API changes
- Breaking changes

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add 5-day forecast support
fix: correct cache expiration time
docs: update API documentation
test: add tests for edge cases
refactor: extract common logic to helper
style: fix code formatting
chore: update dependencies
```

### Pull Request Process

1. **Update Documentation:**
   - Update README if needed
   - Add/update code comments
   - Update CHANGELOG

2. **Ensure Tests Pass:**
   ```bash
   bundle exec rspec
   ```

3. **Check Code Quality:**
   ```bash
   rubocop
   ```

4. **Fill Out PR Template:**
   - Description of changes
   - Issue number (if applicable)
   - Screenshots (for UI changes)
   - Testing performed

5. **Request Review:**
   - Assign reviewers
   - Address feedback
   - Keep PR focused

### PR Template

```markdown
## Description
Brief description of changes

## Related Issue
Fixes #(issue number)

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code follows style guidelines
- [ ] All tests passing
- [ ] No new warnings
```

## Areas for Contribution

### Good First Issues

- Add additional weather providers
- Improve error messages
- Add more test coverage
- Update documentation
- Fix typos

### Feature Requests

- Historical weather data
- Weather alerts
- Multiple location comparison
- Export forecast data
- Mobile responsiveness improvements

### Bug Reports

When reporting bugs, include:

1. **Description:** What happened vs. what you expected
2. **Steps to Reproduce:**
   ```
   1. Go to '...'
   2. Click on '...'
   3. See error
   ```
3. **Environment:**
   - OS: [e.g., macOS 13.0]
   - Ruby: [e.g., 3.3.1]
   - Rails: [e.g., 7.1.0]
4. **Error Messages:** Full error output
5. **Screenshots:** If applicable

## Architecture Decisions

### When Adding New Services

1. Create in appropriate namespace
2. Follow Service Object Pattern
3. Add comprehensive tests
4. Document public API
5. Update facade if needed

Example:
```ruby
module Weather
  class AlternativeWeatherService
    def initialize(api_client: AlternativeApiClient.new)
      @api_client = api_client
    end
    
    def get_weather(lat, lon)
      # Implementation
    end
  end
end
```

### When Adding New Endpoints

1. Add route to `config/routes.rb`
2. Create/update controller
3. Add views if needed
4. Write controller tests
5. Update documentation

### When Changing Database Schema

1. Create migration
2. Update models
3. Update tests
4. Document changes
5. Consider backward compatibility

## Questions?

- Open an issue for questions
- Tag with `question` label
- Check existing discussions first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! 🎉

