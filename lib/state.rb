# @file
# Describes a State object which is a segment of work as used in a Task object.
# Each state defines a segment of work, the next segment of work, retries and
# wait time between states. The states are defined as State objects.

require 'rubygems'

class State
  attr_accessor :from
  attr_accessor :to
  attr_accessor :wait
  attr_accessor :retries
  attr_accessor :attempts

  # Constructor
  #
  # @param [Hash] init
  #   A hash containing default arguments. e.g.
  #   - :from - the state that you are moving from.
  #   - :to - the state that you are moving to.
  #   - :wait - the amount of time to wait between states.
  #   - :retries - the maximum number of retries.
  def initialize init
    @from = init[:from]
    @to = init[:to]
    @wait = init[:wait]
    @retries = init[:retries]
    @attempts = 0
  end
end


