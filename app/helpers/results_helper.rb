module ResultsHelper
  def format_date(full_timestamp)
    full_timestamp.strftime("%d/%m/%Y")
  end

  def show_link_if_events_found(result)
    if result.events.empty?
      '0'
    else
      link_to result.events.count, result
    end
  end
end