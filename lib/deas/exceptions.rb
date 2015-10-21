module Deas

  Error = Class.new(RuntimeError)
  ServerError = Class.new(Error)

  ServerRootError = Class.new(ServerError) do
    def message
      "server `root` not set but required"
    end
  end

  NoHandlerClassError = Class.new(Error) do
    def initialize(handler_class_name)
      super "Deas couldn't find the view handler '#{handler_class_name}'" \
            " - it doesn't exist or hasn't been required in yet."
    end
  end

  HandlerProxyNotFound = Class.new(Error)

  NotFound = Class.new(Error)

end
