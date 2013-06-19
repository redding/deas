require 'deas/view_handler'

module Deas
  class RouteProxy

    attr_reader :handler_class_name

    def initialize(handler_class_name)
      @handler_class_name = handler_class_name
    end

    def handler_class
      constantize(@handler_class_name).tap do |handler_class|
        raise(NoHandlerClassError.new(@handler_class_name)) if !handler_class
      end
    end

    private

    def constantize(class_name)
      names = class_name.to_s.split('::').reject{ |name| name.empty? }
      klass = names.inject(Object){ |constant, name| constant.const_get(name) }
      klass == Object ? false : klass
    rescue NameError
      false
    end

    class NoHandlerClassError < RuntimeError
      def initialize(handler_class_name)
        super "Deas couldn't find the view handler '#{handler_class_name}'" \
              " - it doesn't exist or hasn't been required in yet."
      end
    end

  end
end
