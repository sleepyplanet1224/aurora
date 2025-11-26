class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
  end

  def dashboard
    # assigned all current user's months in ascending order to var user_months
    user_months = current_user.months.order(:date)

    # set both the start and end dates for the graph to display
    #TODO: Remember to make this part dynamic depending on what the user chooses
    start_date = Date.current.beginning_of_month
    end_date   = start_date + 11.months

    # assigned the date range to a variable chart_projection
    @date_range = user_months.where(date: start_date..end_date)

    # begin w/ assets of the first month in the projection range window
    base_asset = @date_range.first.total_assets

    # iterate over each month inside range of projection
    @chart_data = @date_range.map do |month|
      # Add this month's saved amount to the running total
      base_asset += month.saved_amount

      # spit out hash for chart kick to process
      [ month.date.strftime("%b %Y"), base_asset ]
    end.to_h
  end
end
