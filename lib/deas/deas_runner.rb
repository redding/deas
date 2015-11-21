require 'rack/utils'
require 'deas/runner'

module Deas

  class DeasRunner < Runner

    def initialize(handler_class, args = nil)
      args ||= {}
      super(
        handler_class,
        args.merge(:params => NormalizedParams.new(args[:params]).value)
      )
    end

    def run
      catch(:halt) do
        self.handler.deas_run_callback 'before'
        catch(:halt){ self.handler.deas_init; self.handler.deas_run }
        self.handler.deas_run_callback 'after'
      end

      self.to_rack.tap do |(status, headers, body)|
        headers['Content-Length'] ||= body.inject(0) do |length, part|
          length + Rack::Utils.bytesize(part)
        end.to_s
      end
    end

    private

    class NormalizedParams < Deas::Runner::NormalizedParams
      def file_type?(value)
        value.kind_of?(::Tempfile)
      end
    end

  end
end
