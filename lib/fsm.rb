require 'pp'

class State
  attr_accessor :from
  attr_accessor :to
  attr_accessor :wait
  attr_accessor :retries
  attr_accessor :attempts
  attr_accessor :action

  def initialize init
    @from = init[:from]
    @to = init[:to]
    @wait = init[:wait]
    @retries = init[:retries]
    @action = init[:action]
    @attempts = 0
  end
end

class Task
  attr_accessor :state_list
  attr_accessor :transition
  attr_accessor :context
  attr_accessor :finished
  attr_accessor :wait
  attr_accessor :retries
  attr_accessor :status
  attr_accessor :history

  def states
    raise "You must override the states method."
  end

  def state from, transition, to, wait, retries, &action
    init = {
      :from => from,
      :to => to,
      :wait => wait,
      :retries => retries,
      :action => action,
      :attempts => 0,
    }
    @state_list[from] ||= {}
    @state_list[from][transition] = State.new init
  end

  def execState
    findNextState
    current_state = @state_list[@state][@transition]

    if !current_state.nil? && !current_state.action.nil?
      @transition = current_state.action.call
    else
      @transition = eval "#{@state}"
    end
    @history.push @state

    @finished = @state == :finish
  end

  def findNextState
    # Allow a :catch transition if the explicit value was not found.
    if @state_list[@state][@transition].nil? && !@state_list[@state][:catch].nil?
      @transition = :catch
    end

    if !@state_list[@state][@transition].nil?
      transition = @state_list[@state][@transition]
    else
      raise "Unable to locate a transition from \"#{@state}\" using the transition \"#{@transition}\""
    end

    if !transition.nil?
      @wait = transition.wait
    else
      @wait = 0
    end

    if !transition.nil?
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

  def initialize
    @state_list = {}
    @state = :prestart_noop
    @transition = :catch
    @context = {}
    @finished = FALSE
    @retries = {}
    @history = []
    state :prestart_noop, :catch, :start, 0, 0
    states
    state :finish, :catch, :finish_noop, 0, 0
  end

  def run
    @wait = 0
    while !@finished && @wait == 0 && @status != :error
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
