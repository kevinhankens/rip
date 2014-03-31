# @file
# Describes a Task object that is used to execute work on. The Task object is a
# finite state machine where each state describes a segment of work, the next
# segment of work, retries and wait time between states. The states are defined
# as State objects.

require 'rubygems'
require 'pp'
require './lib/state.rb'

class Task
  attr_accessor :id
  attr_accessor :state_list
  attr_accessor :transition
  attr_accessor :context
  attr_accessor :finished
  attr_accessor :wait
  attr_accessor :retries
  attr_accessor :status
  attr_accessor :history
  attr_accessor :title
  attr_accessor :class_path

  @@statuses = {
    :not_started => 1,
    :restarted   => 2,
    :running     => 4,
    :waiting     => 8,
    :error       => 16,
    :finished    => 36,
    :killed      => 64,
  }

  # Retrieves the current status.
  def getStatus
    @@statuses[@status]
  end

  # Abstract method must be overridden.
  def states
    raise "You must override the states method."
  end

  # Defines a state to use in the FSM.
  #
  # @param [Symbol] from
  # @param [Symbol, String] transition
  # @param [Symbol] to
  # @param [Symbol] wait
  # @param [Symbol] retries
  def state from, transition, to, wait, retries
    init = {
      :from => from,
      :to => to,
      :wait => wait,
      :retries => retries,
      :attempts => 0,
    }
    @state_list[from] ||= {}
    @state_list[from][transition] = State.new init
  end

  # Executes a specified state given the previous transition.
  def execState
    findNextState
    current_state = @state_list[@state][@transition]

    @transition = eval "#{@state}"
    @history.push @state

    @finished = @state == :finish
  end

  # Locates the next state. 
  #
  # Sets @state based on the previous transition or tries :catch if no suitable
  # transition was found.
  def findNextState
    # Allow a :catch transition if the explicit value was not found.
    if @state_list[@state][@transition].nil? && !@state_list[@state][:catch].nil?
      @transition = :catch
    end

    # Attempt to find a suitable state given the most recent @transition value.
    if !@state_list[@state][@transition].nil?
      transition = @state_list[@state][@transition]
    else
      raise "Unable to locate a transition from \"#{@state}\" using the transition \"#{@transition}\""
    end

    if !transition.nil? && !transition.wait.nil?
      @wait = transition.wait
    else
      @wait = 0
    end

    if !transition.nil? && !transition.retries.nil?
      @retries = transition.retries
    else
      @retries = 0
    end

    transition.attempts += 1
    if transition.retries > 0
      if transition.attempts > transition.retries
        raise "Too many retries"
      end
    end

    @state = transition.to
  end

  # Constructor
  def initialize
    @title = 'Task'
    @state_list = {}
    @state = :prestart_noop
    @transition = :catch
    @context = {}
    @finished = FALSE
    @retries = {}
    @history = []
    @class_path = self.path
    @status = :not_started
    state :prestart_noop, :catch, :start, 0, 0
    states
    state :finish, :catch, :finish_noop, 0, 0
  end

  def path
    raise "You must override the states method."
  end

  def getPath
    @class_path 
  end

  # Executes state transitions until wait, finish or error.
  def run
    @wait = 0
    @status = @@statuses[:running]
    while !@finished && @wait == 0 && @status != @@statuses[:error]
      begin
        execState
      rescue
        pp $!
        pp $@
        puts "An error occured."
        @status = :error
      end
    end

    # The only way it exits the loop is if the task is finished or waiting.
    @status = @finished ? :finished : :waiting
  end

end
