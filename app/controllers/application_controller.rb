class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    @test_message = "This is my test message"
  end
end
