require 'deas/handler_proxy'
require 'deas/url'
require 'deas/view_handler'

module Deas

  class RespondWithProxy < HandlerProxy

    attr_reader :handler_class_name, :handler_class

    def initialize(halt_args)
      @handler_class = Class.new do
        include Deas::ViewHandler

        def self.halt_args; @halt_args; end
        def self.halt_args=(value)
          @halt_args = value
        end

        def self.name; 'Deas::RespondWithHandler'; end

        attr_reader :halt_args

        def init!
          @halt_args = self.class.halt_args
        end

        def run!
          halt *self.halt_args
        end

      end

      @handler_class.halt_args = halt_args
      @handler_class_name = @handler_class.name
    end

    def validate!; end

  end

end
