#Yet another background processing abstraction layer

Assuming that every time you want to do something in a background job, it's defined in a method on an active record object.

Zero explicit dependencies. (just respond to `id` and `find` like AR does)

##Example

gem is called `async-jobs`

```ruby
  require 'async'
  require 'async/resque'
  Async.backend = Async::ResqueBackend

  class Invoice < ActiveRecord::Base
    def process(arg)
      Async.run{ process_now(arg)}
    end
    def process_now(arg)
      #actually do it
    end
  end

  invoice.process 1
```

Will enqueue a Resque job that runs `invoice.process_now 1`