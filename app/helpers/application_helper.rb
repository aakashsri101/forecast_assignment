# frozen_string_literal: true

# View helpers for the entire application
module ApplicationHelper
  def format_temperature(temp, unit = '°F')
    "#{temp.round}#{unit}".html_safe
  end

  def cache_status_message(from_cache, cached_at = nil)
    if from_cache && cached_at
      "Data from cache (retrieved #{time_ago_in_words(cached_at)} ago)"
    elsif from_cache
      'Data from cache'
    else
      'Fresh data from API'
    end
  end

  def cache_indicator_class(from_cache)
    from_cache ? 'cached' : 'fresh'
  end
end

