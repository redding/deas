require 'deas/view_handler'

module Deas
  class RedirectProxy

    attr_reader :handler_class_name, :handler_class

    def initialize(path = nil, &block)
      @handler_class = Class.new do
        include Deas::ViewHandler

        def self.redirect_path; @redirect_path; end
        def self.redirect_path=(value)
          @redirect_path = value
        end

        def self.name; 'Deas::RedirectHandler'; end

        def run!
          redirect self.instance_eval(&self.class.redirect_path)
        end

      end
      @handler_class.redirect_path = path ? proc{ path } : block
      @handler_class_name = @handler_class.name
    end

  end
end
