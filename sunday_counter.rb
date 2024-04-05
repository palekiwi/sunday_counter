module SundayCounter
  # configuration of initial conditions
  # :ref_year         Reference year, eg. 1900
  # :ref_first_day    Name of first day in refernce year, eg. "Monday"
  # :year_layout      Layout of day count in a non-leap year, eg. [31, 28, 31, ...]
  # :leap_layout      Layout of day count in a leap year, eg. [31, 29, 31, ...]
  # :leap_predicate   Lambda predicate, returns true if year is leap, false if non-leap
  Config = Struct.new(
    :ref_year, :ref_first_day, :year_layout, :leap_layout, :leap_predicate
  )

  DEFAULT_YEAR = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  DEFAULT_LEAP = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  DEFAULT_LEAP_PREDICATE = ->(year) { (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) }

  WEEKDAYS = {
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
    sunday: 7
  }

  class Counter
    def initialize(config)
      raise "Reference year must be provided" if config[:ref_year].nil?
      raise "First day of reference year must be provided" if config[:ref_first_day].nil?
      fd = config[:ref_first_day].downcase.to_sym
      raise "Invalid first day provided" if WEEKDAYS[fd].nil?

      @year_layout = config[:year_layout] || DEFAULT_YEAR
      @leap_layout = config[:leap_layout] || DEFAULT_LEAP
      @ref_year = config[:ref_year]
      @ref_offset = WEEKDAYS[fd] - 1
      @leap_pred = config[:leap_predicate] || DEFAULT_LEAP_PREDICATE

      year_length = @year_layout.sum
      leap_length = @leap_layout.sum

      @offset_year = year_length % 7
      @offset_leap = leap_length % 7

      @firsts_year = get_first_days(@year_layout)
      @firsts_leap = get_first_days(@leap_layout)

      @memo = {}
    end

    # map first days of each month to absolute days in a year
    # e.g. Jan 1 -> 1, Feb 1 -> 32
    def get_first_days(months)
      months[...-1].reduce([1]) do |acc, x|
        acc << acc[-1] + x
      end
    end

    # given a day in the year, decide if it's a Sunday,
    # considering an offset from a year that would start on a Monday
    def is_sunday(day, offset)
      (day + offset) % 7 == 0
    end

    # increment offset for a year depending if leap or not
    def inc_offset(leap, current_offset)
      ((leap ? @offset_leap : @offset_year) + current_offset) % 7
    end

    def count_sundays(days, offset)
      days.reduce(0) { |sum, day| is_sunday(day, offset) ? sum + 1 : sum }
    end

    def total_sundays_since_ref(limit)
      (@ref_year..limit).each_with_object([0, @ref_offset]) do |year, acc|
        leap = @leap_pred.call(year)
        offset = acc[1]
        key = offset.to_s + leap.to_s
        if @memo.include?(key)
          count = @memo[key]
        else
          days = leap ? @firsts_leap : @firsts_year
          count = count_sundays(days, offset)
          @memo[key] = count
        end
        acc[0] += count
        acc[1] = inc_offset(leap, offset)
      end[0]
    end

    def total_sundays(from, to)
      raise "Minimum year is #{@ref_year})" if from < @ref_year
      raise "First year must be less than or equal second year" if to < from
      total_sundays_since_ref(to) - total_sundays_since_ref(from - 1)
    end
  end
end
