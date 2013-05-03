require 'deas/sinatra_runner'

module Deas

  class Route
    attr_reader :method, :path, :handler_class_name, :handler_class

    def initialize(method, path, handler_class_name)
      @method = method
      @path   = path
      @handler_class_name = handler_class_name
      @handler_class      = nil
    end

    def constantize!
      @handler_class ||= constantize_name(handler_class_name)
      raise(NoHandlerClassError.new(handler_class_name)) if !@handler_class
    end

    def run(sinatra_call)
      sinatra_call.request.env.tap do |env|
        env['sinatra.params']     = sinatra_call.params
        env['deas.handler_class'] = @handler_class
      end
      Deas::SinatraRunner.run(@handler_class, sinatra_call)
    end

    private

    def constantize_name(class_name)
      names = class_name.to_s.split('::').reject{|name| name.empty? }
      klass = names.inject(Object) do |constant, name|
        constant.const_get(name)
      end
      klass == Object ? false : klass
    rescue NameError
      false
    end

  end

  class NoHandlerClassError < RuntimeError
    def initialize(handler_class_name)
      super "Deas couldn't find the view handler '#{handler_class_name}'. " \
        "It doesn't exist or hasn't been required in yet."
    end
  end

end
