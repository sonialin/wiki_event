class ResultsController < ApplicationController
  def index
    @results = Result.paginate(:page => params[:page], :per_page => 15)
  end

  def new
    @result = Result.new
  end

  def show
    @result = Result.find(params[:id])
  end

  def create
    @result = Result.new(result_params)
    matched_result = Result.find_by(queried_date: @result.queried_date)
    if matched_result
      @result = matched_result
    else
      @result.save
      scrape_and_save_events
    end
    redirect_to @result
  end

  private
  def result_params
    params.require(:result).permit(:queried_date)
  end

  def scrape_and_save_events
    date, month, year = @result.queried_date.strftime("%d %B %Y").split
    scrape_events(date, month, year)
    
    @events_in_category_raw.each_with_index do |list_of_events, category_index|
      events = list_of_events.xpath('li')
      events.each do |event|
        event_link_raw = event.css('a').first['href']
        full_link = absolute_link(event_link_raw)
        event_digest = scrape_event_digest(full_link)
        save_event(event_digest, category_index)
      end
    end
  end

  def scrape_events(date, month, year)
    content= HTTParty.get('https://en.wikipedia.org/wiki/Portal:Current_events/' + month + '_' + year + '#' + year + '_' + month + '_' + date,
      :headers =>{'Content-Type' => 'application/json'} )
    page = Nokogiri::HTML(content)
    events_section = page.css('table').css('table.vevent')[date.to_i - 1].css('tr').css('td.description')
    categories_raw = events_section.css('dl').css('dt') rescue nil
    if categories_raw
      @category_ids = []
      categories_raw.each do |category|
        found_category = Category.where('lower(name) = ?', category.text.downcase).first
        found_category ||= Category.create(:name => category.text)
        @category_ids << found_category.id
      end
    end
    @events_in_category_raw = events_section.xpath('ul')
  end

  def scrape_event_digest(event_link)
    raw_content = HTTParty.get(event_link, :headers =>{'Content-Type' => 'application/json'})
    page = Nokogiri::HTML(raw_content)
    title = page.at('h1').text
    summary = page.xpath('//div[@class="mw-parser-output"]/p[./following-sibling::div[@id="toc"] or following-sibling::div[starts-with(@class, "toc")]]').to_s
    if summary.empty?
      summary = 'n/a'
    end
    image_link = page.xpath('//div[@class="mw-parser-output"]').css('a.image').first.attributes['href'].text rescue nil
    digest = {title: title, summary: summary, image_link: image_link}
  end

  def absolute_link(scraped_link)
    full_link = ''
    if !scraped_link.start_with?('/wiki')
      full_link = scraped_link
    else
      full_link = 'https://en.wikipedia.org' + scraped_link
    end
    full_link
  end

  def save_event(event_digest, category_index)
    new_event = Event.new(title: event_digest[:title], image_link: event_digest[:image_link], summary: event_digest[:summary])
    new_event.result = @result
    if @category_ids && @category_ids.any?
      new_event.category = Category.find(@category_ids[category_index])
    end
    new_event.save
  end
end