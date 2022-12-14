require 'date'

##
# Provides helper functions to find previous dates.

module Days
  ##
  # Provides the prior +weekday+ based on +date+.
  #
  # +date+ is the date object you want to count from
  # +weekday+ is the target day you want to get back
  def self.prior_weekday(date, weekday)
    weekday_index = Date::DAYNAMES.reverse.index(weekday)
    days_before = (date.wday + weekday_index) % 7 + 1
    date.to_date - days_before
  end

  ##
  # Provides date for yesterday.
  def self.yesterday
    Date.today.prev_day
  end

  ##
  # Provides the start and end dates for a given +week+ in the given +year+
  def self.get_days(week, year)
    start_day = Date.commercial(year, week, 1)
    end_day = Date.commercial(year, week, 7)
    [start_day, end_day]
  end

  ##
  # Provides the week given a date
  # +year+, +month+ and +day+ should be provided for the target date.
  def self.get_days_from_week(year, month, day)
    date = Date.new(year, month, day)
    get_days(date.cweek, date.cwyear)
  end
end