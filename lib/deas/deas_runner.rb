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

    private

    def run_callbacks(callbacks)
      callbacks.each{ |proc| self.handler.instance_eval(&proc) }
    end

    class NormalizedParams < Deas::Runner::NormalizedParams
      def file_type?(value)
        value.kind_of?(::Tempfile)
      end
    end

  end
end
