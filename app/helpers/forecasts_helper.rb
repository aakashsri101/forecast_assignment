# frozen_string_literal: true

# View helpers specific to forecast views
module ForecastsHelper
  def format_forecast_date(date)
    Date.parse(date.to_s).strftime('%A, %B %d')
  rescue ArgumentError
    date.to_s
  end

  def temperature_color_class(temp_f)
    case temp_f
    when 0..32 then 'text-blue-600'
    when 33..60 then 'text-blue-400'
    when 61..80 then 'text-green-500'
    when 81..90 then 'text-orange-500'
    else       'text-red-600'
    end
  end

  def format_wind(speed_mph, direction)
    "#{speed_mph.round} mph #{direction}"
  end
end

