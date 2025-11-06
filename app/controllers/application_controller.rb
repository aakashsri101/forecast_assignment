# frozen_string_literal: true

# Base controller providing common functionality and error handling
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from StandardError, with: :handle_standard_error

  private

  def handle_standard_error(exception)
    Rails.logger.error("Error: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    flash[:error] = 'An error occurred while processing your request. Please try again.'
    redirect_to root_path
  end
end

