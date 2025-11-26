class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
  end

  def dashboard
    @event = Event.new
    @events = Event.all.order(created_at: :desc)
  end
end
