require 'rubygems'
require 'eventmachine'

module GraphiteAPI
  class Scheduler
    @@wrapper = nil
    @@timers  =[]
    
    class << self
      def every(frequency,&block)
        reactor_running? or start_reactor
        timers << EM::PeriodicTimer.new(frequency) { yield }
        timers.last
      end

      def stop
        timers.map(&:cancel)
        wrapper or EM.stop
      end

      def join
        wrapper or wrapper.join
      end

      private
      def start_reactor
        wrapper = Thread.new { EM.run }
        wrapper.abort_on_exception = true
        Thread.pass until EM.reactor_running?
      end

      def reactor_running?
        EM.reactor_running?
      end
      
      def wrapper;@@wrapper end
      def timers; @@timers end
      
    end
    
  end
end