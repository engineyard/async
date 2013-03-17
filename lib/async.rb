class Async
  class << self
    attr_accessor :backend
  end

  class MethodCatcher
    attr_reader :_method_name, :_args
    def method_missing(method_name, *args)
      @_method_name = method_name
      @_args = args
    end
  end

  def self.ensure_backend!
    unless Async.backend
      raise "Please configure the background processing system of choice by setting: Async.backend="
    end
  end

  def self.run(&block)
    ensure_backend!
    receiver = block.binding.eval("self")
    mc = MethodCatcher.new
    mc.instance_eval(&block)
    run_later self.to_s, receiver, mc._method_name, *mc._args
  end

  def self.run_later(job_class, receiver, method_name, *args)
    if receiver.is_a?(Class)
      receiver_class, receiver_id = receiver.to_s, nil
    else
      receiver_class, receiver_id = receiver.class.to_s, receiver.id
    end
    Async.backend.enqueue Async.backend.job_class, job_class, receiver_class, receiver_id, method_name, Job.transform_args(args)
  end

  def self.run_now(receiver, method_name, args)
    Notifications.notify_job("run", receiver, method_name, args)
    receiver.send(method_name, *args)
  ensure
    Notifications.notify_job("finish", receiver, method_name, args)
  end

  #TODO: test this
  class Notifications
    class << self
      attr_accessor :handler
    end
    def self.notify_lock(thing, lock_name)
      handler && handler.call(thing, {:lock_name => lock_name})
    end
    def self.notify_job(thing, receiver, method_name, args)
      handler && handler.call(thing, {
        :receiver => receiver,
        :method_name => method_name.to_sym,
        :args => args
      })
    end
  end

  #TODO: test this
  class ErrorReporting
    class << self
      attr_accessor :handler
    end
    def self.notify_exception(e, job_args)
      handler && handler.call(e, job_args)
    end
  end

  class Job

    def self.perform(wrapper, receiver_class_str, receiver_id, method, args)
      receiver_class = constantize(receiver_class_str)
      receiver = receiver_id ? receiver_class.find(receiver_id) : receiver_class
      untransform_args = untransform_args(args)
      constantize(wrapper).run_now(receiver, method, untransform_args)
    rescue => e
      ErrorReporting.notify_exception(e, 
        receiver_class_str: receiver_class_str, receiver_id: receiver_id, method: method, args: args)
    end

    def self.transform_args(args)
      args.map do |x|
        if x.class.respond_to?(:find)
          {'_transform_arg' => true, 'class' => x.class.to_s, 'id' => x.id}
        elsif x.is_a?(Array)
          transform_args(x)
        else
          x
        end
      end
    end

    def self.untransform_args(args)
      args.map do |x|
        if x.is_a?(Hash) && x['_transform_arg']
          constantize(x['class']).find(x['id'])
        elsif x.is_a?(Array)
          untransform_args(x)
        else
          x
        end
      end
    end

    private

    def self.constantize(str)
      if str.respond_to?(:constantize)
        str.constantize
      else
        eval(str)
      end
    end

  end

end