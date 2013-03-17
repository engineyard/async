class Async

  class QuBackend

    def self.enqueue(job_class, *args)
      Qu.enqueue(job_class, *args)
    end

    def self.job_class
      Async::Job
    end

  end

end