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

    def ==(other_handler)
      self.class == other_handler.class
    end

    protected

    # Helpers

    def halt(*args);         @deas_runner.halt(*args);         end
    def redirect(*args);     @deas_runner.redirect(*args);     end
    def content_type(*args); @deas_runner.content_type(*args); end

    def render(*args, &block)
      @deas_runner.render(*args, &block)
    end

    def app_settings; @deas_runner.app_settings; end
    def logger;       @deas_runner.logger;       end
    def request;      @deas_runner.request;      end
    def response;     @deas_runner.response;     end
    def params;       @deas_runner.params;       end
    def session;      @deas_runner.session;      end

    def run_callback(callback)
      (self.class.send("#{callback}_callbacks") || []).each do |callback|
        self.instance_eval(&callback)
      end
    end

    module ClassMethods

      def layout(*args)
        @layouts = args unless args.empty?
        @layouts
      end
      alias :layouts :layout

      def before_callbacks; @before_callbacks ||= []; end
      def after_callbacks;  @after_callbacks  ||= []; end
      def before_init_callbacks; @before_init_callbacks ||= []; end
      def after_init_callbacks;  @after_init_callbacks  ||= []; end
      def before_run_callbacks;  @before_run_callbacks  ||= []; end
      def after_run_callbacks;   @after_run_callbacks   ||= []; end

      def before(&block); self.before_callbacks << block; end
      def after(&block);  self.after_callbacks  << block; end
      def before_init(&block); self.before_init_callbacks << block; end
      def after_init(&block);  self.after_init_callbacks  << block; end
      def before_run(&block);  self.before_run_callbacks  << block; end
      def after_run(&block);   self.after_run_callbacks   << block; end
      def prepend_before(&block); self.before_callbacks.unshift(block); end
      def prepend_after(&block);  self.after_callbacks.unshift(block);  end
      def prepend_before_init(&block); self.before_init_callbacks.unshift(block); end
      def prepend_after_init(&block);  self.after_init_callbacks.unshift(block);  end
      def prepend_before_run(&block);  self.before_run_callbacks.unshift(block);  end
      def prepend_after_run(&block);   self.after_run_callbacks.unshift(block);   end

    end

  end

end
