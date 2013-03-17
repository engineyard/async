require 'cubbyhole/base'
class Yard < Cubbyhole::Base

  def self.backend
    @backend ||= Hash.new
  end

  def self.find(id)
    get(id)
  end

  def do_all_the_work(which)
    Async::Locked.run{ now_do_all_the_work(which) }
  end

  def now_do_all_the_work(which)
    # puts "do_all_the_work"
    trim(which)
    mow(which)
  end

  def trim(which)
    Async::Locked.run{ now_trim(which) }
  end

  def now_trim(which)
    # puts "trim #{which}"
  end

  def mow(which)
    Async.run{ now_mow(which) }
  end
  def now_mow(which)
    # puts "mow #{which}"
    self.mowed = which
    self.save
    Yard.burn
  end

  def self.burn
    Async.run{ now_burn }
  end
  def self.now_burn
    # puts "burning..."
  end

  def conflict
    Async::Locked.run{ now_conflict }
  end
  def now_conflict
    # puts "conflict"
  end

end
