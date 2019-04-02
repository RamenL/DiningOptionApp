require_relative 'dining'
require 'csv'
require 'date'
require 'time'

#constants
PRICES = ['expensive', 'medium', 'inexpensive']
HOURS_IN_DAY = 12
HALF_HOUR = 30
ROUNDED_TIME = '00'
END_OF_TIME_CYCLE = 12

=begin
Function: remove_character
Pre-Condition: called when dining inputs are compared against dining_constraints
Post-Condition: returns a string with the specificied character removed
=end
def remove_character(dining_string, char)
  dining_string.sub!(/char/, '') if dining_string.include? "\'"
  dining_string.to_s.downcase
end

=begin
Function: trim_zero
Pre-Condition: called when date is being parsed
Post-Condition: returns a integer without leading zeros
=end
def trim_zero(date_string)
  date_string.sub!(/^0*/, '').to_i
end

=begin
Function: validate_date
Pre-Condition: called to validate user date input
Post-Condition: returns boolean if date is valid
=end
def validate_date(date_input)
  begin
    Date.parse(date_input)
  rescue ArgumentError
    return false
  end
end

=begin
Function: round_time 
Pre-Condition: called before validating user time input 
Post-Condition: returns time to nearest hour
=end
def round_time(time_input)
  time_obj = Time.parse(time_input)
  time_hour = time_obj.hour.to_i
  meridiem = time_hour < END_OF_TIME_CYCLE ? "AM" : "PM"
  time_hour = time_hour + 1 if time_obj.min.to_i >= HALF_HOUR
  time_hour = time_hour - END_OF_TIME_CYCLE if time_hour > END_OF_TIME_CYCLE
  time_hour = "0" << time_hour.to_s if time_hour.to_s.length == 1
  time_hour.to_s << ":" << ROUNDED_TIME << meridiem
end

=begin
Function: validate_time
Pre-Condition: called to validate user input time with Time object
Post-Condition: returns a boolean
=end
def validate_time(time_input)
  return false if time_input.length != 7 # make sure time length is correct #TODOOOO

  begin
    Time.parse(time_input)
  rescue ArgumentError
    return false
  end
end

=begin
Function: validate_file
Pre-Condition: called to validate both user input files exist
Post-Condition: returns a boolean
=end
def validate_file(filepath)
  File.file?(filepath)
end

=begin
Function: validate_cost
Pre-Condition: called to make sure that user input matches one of the options
Post-Condition: returns boolean
=end
def validate_cost(meal_input)
    PRICES.include? meal_input.upcase
end

=begin
Function: validate_dining_input
Pre-Condition: called to make sure that user dining input matches dining options
Post-Condition: returns boolean
=end
def validate_dining_input(dining_input)
  dining_input.casecmp('dine in').zero? || 
    dining_input.casecmp('grab and go').zero? || 
    dining_input.casecmp('dine in | grab and go').zero?
end

=begin
Function: call_validate_methods
Pre-Condition: this method is called to validate each user input
Post-Condition: returns an array of strings referencing each error type
=end
def call_validate_methods(constraints, historical, day_of_week_input, dining_input, time_input, meal_input)
  errors = []
  errors << 'constraints_file' unless validate_file(constraints)
  errors << 'historical_file' unless validate_file(historical)
  errors << 'date' unless validate_date(day_of_week_input)
  errors << 'time' unless validate_time(time_input)
  errors << 'dining_options' unless validate_dining_input(dining_input.to_s)
  errors << 'meal_options' if validate_cost(meal_input)
  errors
end

# HashMap that contains all error messages
error_msg = { 'date' => 'Date Input Format is incorrect',
              'time' => 'Time Input Format is incorrect',
              'constraints_file' => 'Constraints file could not be found',
              'historical_file' => 'Historical file could not be found',
              'dining_options' => 'Choose from the following Dining Options: Dine In, Grab and go, Dine in | Grab and go',
              'meal_options' => 'Choose from the following Meal Options: Expensive, Medium, Inexpensive',
              'no_dine_match' => 'There are no dining options that match your search criteria',
              'user_instructions' => "Usage: ruby app_dining_option.rb <constraint file> <historical file> <dining type> <cost> <day of the week> <time>" << "\n" <<
                "Example: ruby app_dining_option.rb \'csv_files/dining_constraints.csv\' \'csv_files/historical_dining.csv\' \'Dine in\' \'Medium\' \'Monday\' \'01:00PM\'" << "\n" <<

                'Dining: Dine In, Grab and go, Dine In | Grab and go' << "\n" <<
                'Meal Cost: Expensive, Medium, Inexpensive' << "\n" <<
                'Days: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday' << "\n" <<
                'Times: 11:00AM, 12:00AM, 01:00AM.....' << "\n" }

# Basic User Instructions
if ARGV.length != 6
  puts(error_msg['user_instructions'])
  exit
end

# define variables
dining_hash_map = {}

constraints = ARGV[0]
historical = ARGV[1]
dining_input = ARGV[2]
meal_input = ARGV[3]
day_of_week_input = ARGV[4]
time_input = round_time(ARGV[5])

# function to call other validation methods and print error messages if validation methods fail
error_check_arr = call_validate_methods(constraints, historical, day_of_week_input, dining_input, time_input, meal_input)

# iterate through error array
if (!error_check_arr.nil? && !error_check_arr.empty?)
  error_check_arr.each { |current_error| puts(error_msg[current_error]) }
  exit
end

# instantiate dining_class and insert into HashMap if Dining Location fulfills user input constraints. Else, skip row and go to next item
CSV.foreach(constraints) do |row|
  dining_hash_map[row[0]] = Dining.new row[0], row[1], row[2], row[3], row[4] if dining_input.casecmp(row[4]).zero? && meal_input.casecmp(row[3]).zero?
end

if dining_hash_map.empty? || dining_hash_map.nil? # exit if no dining Locations match user constraints
  puts(error_msg['no_dine_match'])
  exit
end

# update the respective class total historical wait time if the row matches user input constraints. Else, skip item
CSV.foreach(historical) do |row|
  dining_hash_map.each do |dining_name, dining_class|
    next if row[2] == 'Date' # skip first row headers
    
    row_parse = row[2].split('/') # parse date
    day_int = Date.new(trim_zero(row_parse[2]),
                       trim_zero(row_parse[0]),
                       trim_zero(row_parse[1])).wday # return integer representing day of week
    dining_class.update(row[1]) if remove_character(dining_name, "\'") == remove_character(row[0], "\'") &&
                                   day_of_week_input == Date::DAYNAMES[day_int] &&
                                   time_input == row[3] &&
                                   row[1] != 'Closed' # match row to user input
  end
end

# display results
dining_hash_map.each do |dining_name, dining_class|
  # check if there are any data to avoid dividing by zero
  #puts('Dining: ' << dining_name << ', Wait Time: Closed' << ', Cost: ' << dining_class.meal_cost.to_s << ', Type: ' << dining_class.dining.to_s) if dining_class.avg_count.zero?
  if dining_class.avg_count.zero?
    puts('Dining: ' << dining_name << ', Wait Time: Closed' << ', Cost: ' << dining_class.meal_cost.to_s << ', Type: ' << dining_class.dining.to_s) 
    next
  end
  puts('Dining: ' << dining_name << ', Wait Time: ' << dining_class.final_avg.to_s << ', Cost: ' << dining_class.meal_cost.to_s << ', Type: ' << dining_class.dining.to_s)
end
