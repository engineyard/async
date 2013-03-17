require 'async'
require 'shared/models'

class TestBackend
  def initialize
    @jobs = []
  end
  def enqueue(job_class, *args)
    @jobs << [job_class, args]
  end
  def run_all_jobs!
    while(job = @jobs.pop)
      job_class, args = job
      job_class.perform(*args)
    end
  end
  def job_class
    Async::Job
  end
end

describe Async do
  before(:all) do
    @test_backend = TestBackend.new
    Async.backend = @test_backend
  end

  it "works" do
    y = Yard.new
    y.save
    y.mowed.should be_nil
    y.mow("front")

    @test_backend.run_all_jobs!

    y.reload
    y.mowed.should eq "front"
  end

end