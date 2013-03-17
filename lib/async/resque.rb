class Async

  class ResqueBackend

    def self.enqueue(job_class, *args)
      Resque.enqueue(job_class, *args)
    end

    def self.job_class
      Async::ResqueBackend::Job
    end

    class Job < Async::Job
      @queue = :default
    end

  end

end