class Dining
  attr_reader :dining_location, :meal_cost, :dining, :wait_time, :avg_count # get methods

=begin
Function: initialize
Pre-condition: called to initialize dining class from contraints file
Post-condition: returns a dining class object
=end
  def initialize(dining_location, week_day_times, week_end_times, meal_cost, dining) # instantiate class
    @dining_location = dining_location
    @week_day_times = week_day_times
    @week_end_times = week_end_times
    @meal_cost = meal_cost
    @dining = dining
    @wait_time = 0 # sum of wait_time
    @avg_count = 0 # number of entries added
  end

=begin
Function: update
Pre-condition: called when historical wait time matches dining option
Post-condition: returns the total wait time and the number of times the wait time has been updated
=end
  def update(wait)
    @wait_time = @wait_time.to_i + wait.to_i
    @avg_count = @avg_count.to_i + 1
  end

=begin
Function: final_avg
Pre-condition: called at the end to find the average wait time
Post-condition: returns the total wait time divided by the updated count to find the mean
=end
  def final_avg
    @wait_time.to_i / @avg_count.to_i # return average
  end
end
