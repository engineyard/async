require 'sidekiq'
class Async

  class SidekiqBackend

    def self.enqueue(job_class, *args)
      job_class.perform_async(*args)
    end

    def self.job_class
      Async::SidekiqBackend::Job
    end

    class Job < Async::Job
      include Sidekiq::Worker

      def perform(*args)
        self.class.perform(*args)
      end

    end

  end

end