require 'pp'
require './lib/fsm.rb'

class TestTask < Task

  attr_accessor :count

  def initialize
    @count = 0
    super
  end

  def states
    state(:start,  :catch,    :state1, 0, 0) { puts 'state1 override' }
    state :state1, :catch,    :state1, 0, 3
    state :state1, 'proceed', :state2, 1, 0
    state :state2, 'proceed', :state3, 0, 0
    state :state3, 'back',    :state2, 0, 0
    state :state3, 'proceed', :finish, 0, 0
  end

  def start
    puts 'start method'
    '*'
  end

  def state1
    @count = @count + 1
    puts 'state1 method'
    return @count < 3 ? 'wait' : 'proceed'
  end

  def state2
    puts 'state2 method'
    'proceed'
  end

  def state3
    @count = @count + 1
    puts 'state3 method'
    return @count < 5 ? 'back' : 'proceed'
  end

  def finish
    puts 'finish method'
  end

end

t = TestTask.new
t.run
puts t.status
t.run
puts t.history
