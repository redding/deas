module Deas
  # TODO: still needed??
  Error = Class.new(RuntimeError)
  ServerError = Class.new(Error)
  ServerRootError = Class.new(ServerError) do
    def message
      "server `root` not set but required"
    end
  end

end
