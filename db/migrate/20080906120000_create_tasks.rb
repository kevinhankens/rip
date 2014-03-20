class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.integer :created
      t.integer :changed
      t.integer :wake
      t.integer :completed
      t.string  :title
      t.text    :data
    end
  end
end
