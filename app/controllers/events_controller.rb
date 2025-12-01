class EventsController < ApplicationController
  def new
    @event = Event.new
    @month = current_user.months.find_by(date: params[:month] + "-01")
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      total_assets = @event.new_total_assets
      saved_amount = @event.new_saved_amount

      @months = current_user.months.where("date >= ? ", @event.month.date).order(:date)
      @months.each do |month|
        month.update(
          total_assets: total_assets,
          saved_amount: saved_amount
        )
        total_assets += saved_amount
        total_assets *= month.interest_rate
      end
      redirect_to dashboard_path, notice: "Event created successfully."
    else
      redirect_to dashboard_path, alert: "Failed to create event."
    end
  end

  private

  def event_params
    params.require(:event).permit(:name, :new_total_assets, :new_saved_amount, :month_id)
  end
end
