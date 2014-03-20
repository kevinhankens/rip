# @file
# Describes a Pool object which is a prioritized pool of Task objects to execute.

require 'rubygems'
require 'pp'
require 'sequel'
require 'mysql2'

class Pool
  attr_reader :db

  # Constructor.
  def initialize
    @db = Sequel.connect('mysql2://root:@localhost/rip')
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
      String  :data, :text=>TRUE
    end
  end

  # Inserts a Task into the pool to be executed.
  #
  # @param [Task] task
  #   The Task object to insert.
  def insert task
    now = Time.now.to_i
    tasks = @db[:tasks]
tasks.delete
    tasks.insert :title => task.title,
                 :status => task.getStatus,
                 :created => now,
                 :changed => 0,
                 :status => 1,
                 :data => Marshal::dump(task)
  end

  # Updates a Task in the pool to track its last state.
  #
  # @param [Task] task
  #   The Task object to update.
  def update task
    now = Time.now.to_i
    tasks = @db[:tasks]
    r = tasks.where(:id => task.id).update :changed => now,
                                           :status => task.getStatus,
                                           :data => Marshal::dump(task)
  end

  # Gets the highest priority Task from the Pool.
  #
  # @return [Task]
  #   The Task object to operate on.
  def getNext
    # @todo lock the object before returning.
    tasks = @db[:tasks]
    db_task = tasks.where('status < 16').order(:wake).order(:created).first
    task = Marshal::load(db_task[:data])
    task.id = db_task[:id]
    task
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

end
