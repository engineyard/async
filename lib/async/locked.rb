class Async
  class << self
    attr_accessor :redis, :lock_time
  end

  class Locked < Async

    def self.run_now(receiver, method_name, args)
      Notifications.notify_job("consider", receiver, method_name, args)
      if Lock.is_lock_arg?(args.first)
        lock_arg = args.shift
        lock = Lock.claim(make_lock_name(receiver)) || Lock.create(make_lock_name(receiver))
      else
        lock = Lock.create(make_lock_name(receiver))
      end
      if lock
        super
      else
        run_later(self.to_s, receiver, method_name, *args)
      end
    ensure
      lock && lock.release
    end

    def self.run_later(job_class, receiver, method_name, *args)
      if lock = Lock.pass_on(make_lock_name(receiver))
        super(job_class, receiver, method_name, lock.as_job_arg, *args)
      else
        super
      end
    end

    def self.make_lock_name(receiver)
      if receiver.is_a?(Class)
        Lock.make_name(receiver.to_s, nil)
      else
        Lock.make_name(receiver.class.to_s, receiver.id)
      end
    end

  end

  class Lock
    def self.make_name(*names)
      "lock:"+names.join(":")
    end

    def initialize(lock_name)
      @lock_name = lock_name
      @passed_on = false
    end

    def self.is_lock_arg?(arg)
      arg.is_a?(Hash) && arg["_lock_arg"]
    end

    def as_job_arg
      {"_lock_arg" => true, 'lock_name' => @lock_name}
    end

    def claim
      Notifications.notify_lock("claim", @lock_name)
      if redis.get(@lock_name) #still locked
        refresh!
        return true
      else
        lock
      end
    end

    def lock
      if redis.setnx(@lock_name, "locked")
        refresh!
        Notifications.notify_lock("lock", @lock_name)
        return true
      else
        return false
      end
    end

    def refresh!
      redis.expire(@lock_name, Async::Locked.lock_time || 15)
    end

    def pass_on
      if @passed_on
        #already passed on, can't pass again
        false
      else
        @passed_on = true
        true
      end
    end

    def release
      if @passed_on
        return false
      end
      redis.del(@lock_name)
      Notifications.notify_lock("release", @lock_name)
      Thread.current["Async::Lock.named"][@lock_name] = nil
      return true
    end

    def redis
      Async::Locked.redis
    end

    def self.thread_kill_lock(lock_name)
      Thread.current["Async::Lock.named"] ||= {}
      Thread.current["Async::Lock.named"][lock_name] = nil
    end

    def self.thread_save_lock(lock_name, lock)
      Thread.current["Async::Lock.named"] ||= {}
      Thread.current["Async::Lock.named"][lock_name] = lock
    end

    def self.thread_fetch_lock(lock_name)
      Thread.current["Async::Lock.named"] ||= {}
      Thread.current["Async::Lock.named"][lock_name]
    end

    def self.claim(lock_name)
      lock = Lock.new(lock_name)
      lock.claim && thread_save_lock(lock_name, lock) && lock
    end

    def self.pass_on(lock_name)
      lock = thread_fetch_lock(lock_name)
      lock && lock.pass_on && lock
    end

    def self.create(lock_name)
      lock = Lock.new(lock_name)
      lock.lock && thread_save_lock(lock_name, lock) && lock
    end

  end

end