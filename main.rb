require_relative "sunday_counter"


# Config struct, only ref_year and ref_first_day are required
# remaining fields have default values provided by module
config = SundayCounter::Config.new(
  ref_year: 1900,
  ref_first_day: "Monday",
  leap_predicate: ->(year) { (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) },
  year_layout: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
  leap_layout: [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
)

result = SundayCounter::Counter.new(config).total_sundays(1901, 2000)

puts result
