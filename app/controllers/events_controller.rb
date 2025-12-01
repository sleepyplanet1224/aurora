class EventsController < ApplicationController

  def new
    @event = Event.new
    @month = current_user.months.find_by(date: params[:month] + "-01")
    @event_name = params.dig(:search, :name)&.strip
  end

  def create
    @event = Event.new(event_params)

    if params[:event][:percentage].present?
      percentage = params[:event][:percentage].to_f
      multiplier = 1 + (percentage / 100.0)

      @event.new_saved_amount = @event.new_saved_amount.to_f * multiplier
    end

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
