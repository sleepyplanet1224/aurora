class ApplyEvents
  def self.call(event, user)
    new(event, user).perform
  end

  def initialize(event, user)
    @event = event
    @current_user = user
  end

  def perform
    return [false, @event] unless @event.save

    events_to_update = @current_user.events
                                    .joins(:month)
                                    .where("months.date >= ?", @event.month.date)
                                    .order("months.date ASC").to_a
    retirement_event_index = events_to_update.index { |event| event.name == "retirement" }
    last_index = events_to_update.length - 1

    events_to_update.each_with_index do |event, index|
      if index < last_index && events_to_update[index + 1].name == "retirement"
        event_end_date = events_to_update[index + 1].month.date.next_month
      elsif index < last_index
        event_end_date = events_to_update[index + 1].month.date
      else
        event_end_date = @current_user.months.last.date.next
      end

      @months = @current_user.months.where("date >= ? AND date < ?", event.month.date, event_end_date).order(:date)

      total_assets = event.new_total_assets.to_f
      saved_amount = event.new_saved_amount.to_f

      @months.each do |month|
        interest_rate = month.interest_rate.to_f.nonzero? || 1.0 # prevent nil or zero

        # At retirement we model spending as a negative "saved_amount".
        applied_saved_amount = saved_amount

        # Log the month-by-month projection around events for easier debugging.
        previous_assets = total_assets

        month.update(
          total_assets: total_assets,
          saved_amount: applied_saved_amount
        )

        total_assets += applied_saved_amount
        total_assets *= interest_rate

        Rails.logger.info(
          "[ApplyEvents] user_id=#{@current_user.id} " \
          "event=#{event.name} month=#{month.date} " \
          "prev_assets=#{previous_assets.round(2)} " \
          "saved_amount=#{applied_saved_amount.round(2)} " \
          "interest_rate=#{interest_rate} " \
          "new_assets=#{total_assets.round(2)}"
        ) if defined?(Rails) && Rails.env.development?
      end

      next unless index < last_index && events_to_update[index + 1].name == "retirement"

      @retirement_event = Event.find_by(name: "retirement")
      @retirement_event.new_total_assets = @months.last.total_assets
      events_to_update[retirement_event_index] = @retirement_event

      begin
        @retirement_event.save!
        puts "SUCCESS: Event saved successfully."
      rescue ActiveRecord::RecordInvalid => e
        puts "ERROR: Record Invalid - #{e.message}"
      rescue ActiveRecord::StatementInvalid => e
        puts "ERROR: Database Statement Invalid - #{e.message}"
      end
    end

    return [true, @event]
  end
end
