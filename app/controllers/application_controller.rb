class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    @test_message = Rails.application.config.test_home_message
  end
end
