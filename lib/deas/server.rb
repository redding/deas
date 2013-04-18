require 'ns-options'
require 'singleton'

module Deas

  class Server
    include Singleton

    class Configuration
      include NsOptions::Proxy
    end

  end

end
