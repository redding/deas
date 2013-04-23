require 'deas/runner'

module Deas

  module ViewHandler

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end

    def initialize(runner)
      @deas_runner = runner
    end

    def init
      self.run_callback 'before_init'
      self.init!
      self.run_callback 'after_init'
    end

    def init!
    end

    def run
      self.run_callback 'before_run'
      data = self.run!
      self.run_callback 'after_run'
      data
    end

    def run!
      raise NotImplementedError
    end

    def inspect
      reference = '0x0%x' % (self.object_id << 1)
      "#<#{self.class}:#{reference} @request=#{self.request.inspect}>"
    end

    protected

    def before_init; end
    def after_init;  end
    def before_run;  end
    def after_run;   end

    # Helpers

    def halt(*args);           @deas_runner.halt(*args);           end
    def render(*args, &block); @deas_runner.render(*args, &block); end

    def logger;   @deas_runner.logger;   end
    def request;  @deas_runner.request;  end
    def response; @deas_runner.response; end
    def params;   @deas_runner.params;   end

    def run_callback(callback)
      self.send(callback.to_s)
    end

    module ClassMethods

      def before(&block)
        self.before_callbacks << block
      end

      def before_callbacks
        @before_callbacks ||= []
      end

      def after(&block)
        self.after_callbacks << block
      end

      def after_callbacks
        @after_callbacks ||= []
      end

      def layout(*args)
        @layouts = args unless args.empty?
        @layouts
      end
      alias :layouts :layout

    end

  end

end
