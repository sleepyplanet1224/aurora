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
      @end_date = @start_date + 35.months # default
    end

    # find months in the date range, order it
    @months = current_user.months
              .includes(:events)
              .where(date: @start_date..@end_date)
              .order(:date)

    @chart_data_saved  = {} # stacked part 1
    @chart_data_other  = {} # stacked part 2
    @chart_data_event  = {} # event marker (total line)

    @months.each do |month|
      base_label  = month.date.strftime("%b %Y")
      event_names = month.events.pluck(:name)

      # Label includes event names if present (for tooltip/x-axis)
      label =
        if event_names.any?
          "#{base_label} – #{event_names.join(', ')}"
        else
          base_label
        end

      saved = month.saved_amount.to_f
      other = month.total_assets.to_f
      total = saved + other

      @chart_data_saved[label] = saved
      @chart_data_other[label] = other

      # Event marker plotted at the total height
      @chart_data_event[label] = total if event_names.any?
    end

    # generate summary
    if ENV["ENABLE_SUMMARY"] == "true"
      @summary = RubyLLM.chat.ask(" Please analyze the following monthly savings data.
        I would like you to:
        Identify the overall trend (e.g., increasing, decreasing, or fluctuating)
        Point out any major spikes or drops
        Highlight any seasonal or cyclical patterns
        Analyze the changes in recent years (especially the last 2–3 years)
        Summarize any notable observations or anomalies and Limit it to 5 lines.
        Treat the data as if you were looking at a line chart—describe the behavior over time, even if no chart is provided.
        The data is #{@chart_data}").content
    end
  end
end
