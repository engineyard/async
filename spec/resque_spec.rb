require 'async'
require 'async/resque'
require 'shared/models'
require 'redis'
require 'resque'

describe Async do
  before(:all) do
    Resque.redis = Redis.new
    Async.backend = Async::ResqueBackend
  end

  it "works" do
    y = Yard.new
    y.save
    y.mowed.should be_nil
    y.mow("front")

    worker = Resque::Worker.new("*")
    while job = worker.reserve
      job.perform
    end

    y.reload
    y.mowed.should eq "front"
  end

end