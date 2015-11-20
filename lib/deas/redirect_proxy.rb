require 'deas/handler_proxy'
require 'deas/url'
require 'deas/view_handler'

module Deas

  class RedirectProxy < HandlerProxy

    attr_reader :handler_class_name, :handler_class

    def initialize(router, location = nil, &block)
      @handler_class = Class.new do
        include Deas::ViewHandler

        def self.router; @router; end
        def self.router=(value)
          @router = value
        end

        def self.redirect_location; @redirect_location; end
        def self.redirect_location=(value)
          @redirect_location = value
        end

        def self.name; 'Deas::RedirectHandler'; end

        attr_reader :redirect_location

        def init!
          @redirect_location = self.class.router.prepend_base_url(
            self.instance_eval(&self.class.redirect_location)
          )
        end

        def run!
          redirect @redirect_location
        end

      end

      @handler_class.router = router
      @handler_class.redirect_location = if location.nil?
        block
      elsif location.kind_of?(Deas::Url)
        proc{ location.path_for(params) }
      else
        proc{ location }
      end
      @handler_class_name = @handler_class.name
    end

    def validate!; end

  end

end
