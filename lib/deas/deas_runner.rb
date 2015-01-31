require 'deas/runner'

module Deas

  class DeasRunner < Runner

    def initialize(handler_class, args = nil)
      a = args || {}
      runner_args = a.merge(:params => NormalizedParams.new(a[:params]).value)
      super(handler_class, runner_args)
    end

    def run
      run_callbacks self.handler_class.before_callbacks
      self.handler.init
      response_data = self.handler.run
      run_callbacks self.handler_class.after_callbacks
      response_data
    end

    def render(template_name, locals = nil)
      source_render(self.template_source, template_name, locals)
    end

    def source_render(source, template_name, locals = nil)
      source.render(template_name, self.handler, locals || {})
    end

    def partial(template_name, locals = nil)
      source_partial(self.template_source, template_name, locals)
    end

    def source_partial(source, template_name, locals = nil)
      source.partial(template_name, locals || {})
    end

    private

    def run_callbacks(callbacks)
      callbacks.each{|proc| self.handler.instance_eval(&proc) }
    end

    class NormalizedParams < Deas::Runner::NormalizedParams
      def file_type?(value)
        value.kind_of?(::Tempfile)
      end
    end

  end
end
