require 'rack/utils'
require 'deas/runner'

module Deas

  class DeasRunner < Runner

    def initialize(handler_class, args = nil)
      a = args || {}
      runner_args = a.merge(:params => NormalizedParams.new(a[:params]).value)
      super(handler_class, runner_args)
    end

    def run
      catch(:halt) do
        run_callbacks self.handler_class.before_callbacks
        catch(:halt){ self.handler.init; self.handler.run }
        run_callbacks self.handler_class.after_callbacks
      end

      self.to_rack.tap do |(status, headers, body)|
        headers['Content-Length'] ||= body.inject(0) do |length, part|
          length + Rack::Utils.bytesize(part)
        end.to_s
      end
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
