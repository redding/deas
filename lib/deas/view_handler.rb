require 'deas/runner'

module Deas

  module ViewHandler

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module InstanceMethods

      def initialize(runner)
        @deas_runner = runner
      end

      def init
        run_callback 'before_init'
        self.init!
        run_callback 'after_init'
      end

      def init!
      end

      def run
        run_callback 'before_run'
        data = self.run!
        run_callback 'after_run'
        data
      end

      def run!
        raise NotImplementedError
      end

      def layouts
        self.class.layouts.map{ |proc| self.instance_eval(&proc) }
      end

      def inspect
        reference = '0x0%x' % (self.object_id << 1)
        "#<#{self.class}:#{reference} @request=#{request.inspect}>"
      end

      def ==(other_handler)
        self.class == other_handler.class
      end

      private

      # Helpers

      def halt(*args);         @deas_runner.halt(*args);         end
      def redirect(*args);     @deas_runner.redirect(*args);     end
      def content_type(*args); @deas_runner.content_type(*args); end
      def status(*args);       @deas_runner.status(*args);       end
      def headers(*args);      @deas_runner.headers(*args);      end

      def render(*args, &block);         @deas_runner.render(*args, &block);         end
      def source_render(*args, &block);  @deas_runner.source_render(*args, &block);  end
      def partial(*args, &block);        @deas_runner.partial(*args, &block);        end
      def source_partial(*args, &block); @deas_runner.source_partial(*args, &block); end
      def send_file(*args, &block);      @deas_runner.send_file(*args, &block);      end

      def request;  @deas_runner.request;  end
      def response; @deas_runner.response; end
      def session;  @deas_runner.session;  end
      def params;   @deas_runner.params;   end
      def logger;   @deas_runner.logger;   end
      def router;   @deas_runner.router;   end

      def run_callback(callback)
        (self.class.send("#{callback}_callbacks") || []).each do |callback|
          self.instance_eval(&callback)
        end
      end

    end

    module ClassMethods

      def layout(path = nil, &block)
        value = !path.nil? ? Proc.new{ path } : block
        self.layouts.push(value) if value
      end

      def layouts
        @layouts ||= []
      end

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

    module TestHelpers

      def self.included(klass)
        require 'rack/request'
        require 'rack/response'
        require 'deas/test_runner'
      end

      def test_runner(handler_class, args = nil)
        args ||= {}
        args[:request]  ||= Rack::Request.new({})
        args[:response] ||= Rack::Response.new
        args[:session]  ||= args[:request].session
        TestRunner.new(handler_class, args)
      end

      def test_handler(handler_class, args = nil)
        test_runner(handler_class, args).handler
      end

    end

  end

end
