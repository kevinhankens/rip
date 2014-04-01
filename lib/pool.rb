# @file
# Describes a Pool object which is a prioritized pool of Task objects to execute.

require 'rubygems'
require 'pp'
require 'logger'
require 'sequel'
require 'mysql2'
require './lib/task.rb'

class Pool
  attr_reader :db

  # Constructor.
  def initialize
    @db = Sequel.connect('mysql2://root:@localhost/rip')
    # @todo variable log level/pluggable logger?
    @logger = Logger.new(STDOUT)
  end

  # Creates the required database tables.
  def initDb
    @db.create_table! :tasks do
      primary_key :id
      Integer :created
      Integer :changed
      Integer :wake
      Integer :completed
      Integer :status
      String  :title
      String  :path
      String  :data, :text=>TRUE
    end

    @db.create_table! :locks do
      Integer :id, :primary_key=>TRUE
      Integer :locked
    end
  end

  # Locks a task to a worker.
  def lock id
    begin
      @db[:locks].insert :id => id, :locked => 1
      return TRUE
    rescue
      return FALSE
    end
  end

  # Unlocks a task.
  def unlock id
    @db[:locks].where(:id => id).delete
  end

  # Inserts a Task into the pool to be executed.
  #
  # @param [Task] task
  #   The Task object to insert.
  def insert task
    now = Time.now.to_i
    tasks = @db[:tasks]
    tasks.insert :title => task.title,
                 :status => task.getStatus,
                 :created => now,
                 :wake => now,
                 :changed => 0,
                 :path => task.getPath,
                 :data => Marshal::dump(task)
  end

  # Updates a Task in the pool to track its last state.
  #
  # @param [Task] task
  #   The Task object to update.
  def update task
    now = Time.now.to_i
    wait = task.wait.nil? ? now : task.wait
    wake = now + wait
    tasks = @db[:tasks]
    r = tasks.where(:id => task.id).update :changed => now,
                                           :status => task.getStatus,
                                           :wake => wake,
                                           :data => Marshal::dump(task)
  end

  # Gets the highest priority Task from the Pool.
  #
  # @return [Task]
  #   The Task object to operate on.
  def getNext
    tasks = @db[:tasks]
    query_statuses = [
      Task.getStatusValue(:not_started),
      Task.getStatusValue(:restarted),
      Task.getStatusValue(:waiting),
    ]
    db_task = tasks.where(:status => query_statuses).order(:wake).order(:created).first
    if !db_task.nil?
      if self.lock db_task[:id]
        begin
          require db_task[:path]
          task = Marshal::load(db_task[:data])
          task.id = db_task[:id]
          status = Task.getStatusValue :running
          tasks.where(:id => task.id).update :status => status
          return task
        rescue
          self.unlock db_task[:id]
        end
      else
        @logger.warn "lock contention for task #{db_task[:id]}"
        return nil
      end
    end
  end

  # Puts a task away.
  #
  # @param [Task] task
  #   The Task object to operate on.
  def close task
    update task
    unlock task.id
  end

  # Runs a task completely until it is finished or has errors.
  #
  # @param [Task] task
  #   The Task object to run.
  def runTask task
    while !task.finished && task.status < 16 do
      task.run

      if task.status == 8 && task.wait > 0
        sleep task.wait
      end
    end
  end

  # Creates a worker that will wait for tasks.
  #
  # @param [Integer] id
  #   The id to assign this worker.
  def worker id
    while 1 do
      # hackish way to quickly query in the case of lock contention.
      5.times do
        begin
          task = self.getNext
          if !task.nil?
            @logger.debug "Worker #{id} executing task #{task.id}"
            task.run
            self.close task
          end
        rescue => e
          @logger.error "Worker #{id} exited with error: #{e}"
        end
      end
      sleep 5
      @logger.debug "Worker #{id} waiting for tasks"
    end
  end

  # Starts N workers.
  #
  # @param [Integer] workers
  #   The number of workers to spawn.
  def daemon workers = 5
    worker_list = []
    workers.times do |id|
      @logger.info "Starting worker #{id}"
      worker_list[id] = Thread.new(id) { |id| worker id }
    end

    worker_list.each {|worker| worker.join;}
  end  

end
