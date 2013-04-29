class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    @test_message = Dessert::Application.config.test_home_message
  end
end
