require 'async'
require 'async/qu'
require 'async/locked'
require 'qu'
require 'redis'
require 'shared/models'

require 'qu-immediate'
class PoppableQu < Qu::Backend::Immediate

  def self.queue
    @queue ||= []
  end

  def enqueue(payload)
    PoppableQu.queue.unshift(payload)
  end

end

describe Async::Locked do
  before(:all) do
    Async.backend = Async::QuBackend
    Async::Locked.redis = Redis.new
  end
  before(:each) do
    @qubackend = Qu.backend
    Qu.backend = PoppableQu.new
  end
  after(:each) do
    Qu.backend = @qubackend
  end

  it "works" do
    Async::Locked.redis.flushdb

    order_of_ops = []
    Async::Notifications.handler = Proc.new do |name, hash|
      # puts [name, (hash[:method_name] || hash[:lock_name]).to_s, hash[:args]].inspect
      order_of_ops << [name, (hash[:method_name] || hash[:lock_name]).to_s]
    end

    Thread.current["Async::Lock.named"] = nil
    y = Yard.new
    y.save
    y.do_all_the_work("front")
    y.conflict

    PoppableQu.queue.size.should eq 2
    next_job = PoppableQu.queue.pop
    next_job.args.should eq ["Async::Locked", "Yard", y.id, :now_do_all_the_work, ["front"]]

    # puts ""
    Thread.current["Async::Lock.named"] = nil
    next_job.perform

    PoppableQu.queue.size.should eq 3
    next_job = PoppableQu.queue.pop
    next_job.args.should eq ["Async::Locked", "Yard", 0, :now_conflict, []]

    # puts ""
    Thread.current["Async::Lock.named"] = nil
    next_job.perform

    PoppableQu.queue.size.should eq 3
    next_job = PoppableQu.queue.pop
    next_job.args.should eq ["Async::Locked", "Yard", y.id, :now_trim, [{"_lock_arg"=>true, "lock_name"=>"lock:Yard:0"}, "front"]]

    # puts ""
    Thread.current["Async::Lock.named"] = nil
    next_job.perform

    PoppableQu.queue.size.should eq 2
    next_job = PoppableQu.queue.pop
    next_job.args.should eq ["Async", "Yard", y.id, :now_mow, ["front"]]

    # puts ""
    Thread.current["Async::Lock.named"] = nil
    next_job.perform

    PoppableQu.queue.size.should eq 2
    next_job = PoppableQu.queue.pop
    next_job.args.should eq ["Async::Locked", "Yard", 0, :now_conflict, []]

    # puts ""
    Thread.current["Async::Lock.named"] = nil
    next_job.perform

    PoppableQu.queue.size.should eq 1
    next_job = PoppableQu.queue.pop
    next_job.args.should eq ["Async", "Yard", nil, :now_burn, []]

    # puts ""
    Thread.current["Async::Lock.named"] = nil
    next_job.perform

    PoppableQu.queue.size.should eq 0

    order_of_ops.should eq [
      ["consider", "now_do_all_the_work"],
      ["lock", "lock:Yard:0"],
      ["run", "now_do_all_the_work"],
      ["finish", "now_do_all_the_work"],
      ["consider", "now_conflict"],
      ["consider", "now_trim"],
      ["claim", "lock:Yard:0"],
      ["run", "now_trim"],
      ["finish", "now_trim"],
      ["release", "lock:Yard:0"],
      ["run", "now_mow"],
      ["finish", "now_mow"],
      ["consider", "now_conflict"],
      ["lock", "lock:Yard:0"],
      ["run", "now_conflict"],
      ["finish", "now_conflict"],
      ["release", "lock:Yard:0"],
      ["run", "now_burn"],
      ["finish", "now_burn"]]
  end

end