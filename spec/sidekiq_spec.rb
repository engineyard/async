require 'async'
require 'async/sidekiq'
require 'shared/models'
require 'sidekiq/testing'

describe "Async sidekiq" do
  before(:all) do
    Async.backend = Async::SidekiqBackend
  end

  it "works" do
    y = Yard.new
    y.save
    y.mowed.should be_nil
    y.mow("front")

    Async::SidekiqBackend::Job.drain

    y.reload
    y.mowed.should eq "front"
  end

end