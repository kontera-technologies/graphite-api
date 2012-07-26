require 'rubygems'
require 'eventmachine'

module GraphiteAPI
  class Reactor
    @@wrapper = nil
    
    class << self
      def every(frequency,&block)
        reactor_running? or start_reactor
        timers << EventMachine::PeriodicTimer.new(frequency) { yield }
        timers.last
      end

      def stop
        timers.each(&:cancel)
        shutdown_hooks.each(&:call)
        wrapper and EventMachine.stop
      end

      def join
        wrapper and wrapper.join
      end
      
      def add_shutdown_hook(&block)
        shutdown_hooks << block
      end
      
      def loop
        EventMachine.reactor_thread.join
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
      
      def wrapper 
        @@wrapper
      end
      
      def timers
        @@timers ||= []
      end
      
      def shutdown_hooks 
        @@shutdown_hooks ||= []
      end
      
    end
    
  end
end