require 'pp'
require './tasks/test.rb'

p = Pool.new
5.times do |id|
  t = TestTask.new
  t.myid = "myid: #{id}"
  p.insert t
end

#p.runTask t
#pp t.history

#
#n = p.getNext
#n.run
#p.update n
#puts n.status
#
#n = p.getNext
#n.run
#p.update n
#puts n.history


