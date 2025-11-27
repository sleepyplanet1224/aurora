class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def dashboard
    # choose start and end dates for the graph to display
    # TODO: Remember to make this part dynamic depending on what the user chooses
    if params[:start_date].present?
      @start_date = Date.parse(params[:start_date] + "-01").beginning_of_month
      # parse turns whatever is inside to date
    else
      @start_date = Date.current.beginning_of_month
    end

    if params[:end_date].present?
      @end_date = Date.parse(params[:end_date] + "-01").beginning_of_month
    else
      @end_date = @start_date + 11.months # default
    end

    # find months in the date range, order it
    @date_range = current_user.months.where(date: @start_date..@end_date).order(:date)
    # begin w/ assets of the first month in the projection range
    base_asset = @date_range.first.total_assets

    # iterate over each month inside projection range then accumulate
    @chart_data = @date_range.map do |month|
      # Add this month's saved amount to last month's base
      base_asset += month.saved_amount

      # spit out hash for chart kick to process
      [month.date.strftime("%b %Y"), month.total_assets + month.saved_amount]
    end.to_h

    # generate summary
    # @summary = RubyLLM.chat.ask(" Please analyze the following monthly savings data.
    #   I would like you to:
    #   Identify the overall trend (e.g., increasing, decreasing, or fluctuating)
    #   Point out any major spikes or drops
    #   Highlight any seasonal or cyclical patterns
    #   Analyze the changes in recent years (especially the last 2–3 years)
    #   Summarize any notable observations or anomalies and Limit it to 5 lines.
    #   Treat the data as if you were looking at a line chart—describe the behavior over time, even if no chart is provided.
    #   The data is #{@chart_data}").content
  end
end
