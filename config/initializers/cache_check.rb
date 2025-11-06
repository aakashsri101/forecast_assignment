# frozen_string_literal: true

# Check Redis connection on startup in development
if Rails.env.development?
  Rails.application.config.after_initialize do
    begin
      # Test Redis connection
      Rails.cache.write('startup_check', Time.current)
      cached_value = Rails.cache.read('startup_check')
      
      if cached_value
        Rails.logger.info "✅ Cache (Redis) connected successfully"
        Rails.logger.info "   Cache store: #{Rails.cache.class.name}"
        Rails.logger.info "   Redis URL: #{ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')}"
      else
        Rails.logger.warn "⚠️  Cache write/read test failed"
      end
      
      # Clean up test key
      Rails.cache.delete('startup_check')
    rescue StandardError => e
      Rails.logger.error "❌ Cache (Redis) connection failed: #{e.message}"
      Rails.logger.error "   Make sure Redis is running: redis-server"
      Rails.logger.error "   Or check with: redis-cli ping"
    end
  end
end

