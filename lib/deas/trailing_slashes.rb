require 'rack/utils'

require 'deas/exceptions'
require 'deas/router'

module Deas

  class TrailingSlashes

    module RequireHandler;   end
    module RequireNoHandler; end
    module AllowHandler;     end

    HANDLERS = {
      Deas::Router::REQUIRE_TRAILING_SLASHES    => RequireHandler,
      Deas::Router::REQUIRE_NO_TRAILING_SLASHES => RequireNoHandler,
      Deas::Router::ALLOW_TRAILING_SLASHES      => AllowHandler
    }

    def initialize(app, router)
      @app    = app
      @router = router

      if !@router.trailing_slashes_set?
        val  = @router.trailing_slashes
        desc = val.nil? ? 'no' : "an invalid (`#{val.inspect}`)"
        raise ArgumentError, "TrailingSlashes middleware is in use but there is "\
                             "#{desc} trailing slashes router directive set."
      end
    end

    # The Rack call interface. The receiver acts as a prototype and runs
    # each request in a clone object unless the +rack.run_once+ variable is
    # set in the environment. Ripped from:
    # http://github.com/rtomayko/rack-cache/blob/master/lib/rack/cache/context.rb
    def call(env)
      if env['rack.run_once']
        call! env
      else
        clone.call! env
      end
    end

    # The real Rack call interface.
    def call!(env)
      HANDLERS[@router.trailing_slashes].run(env){ @app.call(env) }
    end

    module Handler

      def redirect(location)
        [302, { 'Location' => location }, ['']]
      end

    end

    module RequireHandler
      extend Handler

      def self.run(env)
        if env['PATH_INFO'][-1..-1] != Deas::Router::SLASH
          self.redirect(env['PATH_INFO']+Deas::Router::SLASH)
        else
          yield
        end
      end

    end

    module RequireNoHandler
      extend Handler

      def self.run(env)
        if env['PATH_INFO'][-1..-1] == Deas::Router::SLASH
          self.redirect(env['PATH_INFO'][0..-2])
        else
          yield
        end
      end

    end

    module AllowHandler
      extend Handler

      def self.run(env)
        status, headers, body = yield
        if env['deas.error'].kind_of?(Deas::NotFound)
          # reset 'deas.error' state
          env['deas.error'] = nil

          # switching the trailing slash of the path info
          env['PATH_INFO'] = if env['PATH_INFO'][-1..-1] == Deas::Router::SLASH
            env['PATH_INFO'][0..-2]
          else
            env['PATH_INFO']+Deas::Router::SLASH
          end

          # retry
          yield
        else
          [status, headers, body]
        end
      end

    end

  end

end
