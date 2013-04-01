require 'async'
require 'async/qu'
require 'shared/models'
require 'qu'
require 'qu-immediate'

describe "Async qu" do
  before(:all) do
    Qu.backend = Qu::Backend::Immediate.new
    Async.backend = Async::QuBackend
  end

  it "works" do
    y = Yard.new
    y.save
    y.mowed.should be_nil
    y.mow("front")

    y.reload
    y.mowed.should eq "front"
  end

end