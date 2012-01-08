require 'rubygems'
require 'eventmachine'

module GraphiteAPI
  class Scheduler
    @@wrapper = nil
    @@timers  = []
    
    class << self
      def every(frequency,&block)
        reactor_running? or start_reactor
        timers << EventMachine::PeriodicTimer.new(frequency) { yield }
        timers.last
      end

      def stop
        timers.map(&:cancel)
        wrapper and EventMachine.stop
      end

      def join
        wrapper and wrapper.join
      end

      private
      def start_reactor
        @@wrapper = Thread.new { EventMachine.run }
        wrapper.abort_on_exception = true
        Thread.pass until reactor_running?
      end

      def reactor_running?
        EventMachine.reactor_running?
      end
      
      def wrapper;@@wrapper end
      def timers; @@timers end
      
    end
    
  end
end