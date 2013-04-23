module Deas

  class Template
    attr_reader :name, :options

    def initialize(sinatra_call, name, options = nil)
      @options = options || {}
      @options[:scope] = RenderScope.new(sinatra_call)

      @sinatra_call = sinatra_call
      @name         = name.to_sym
    end

    def render
      @sinatra_call.erb(@name, @options)
    end

    class RenderScope
      def initialize(sinatra_call)
        @sinatra_call = sinatra_call
      end

      def partial(name, locals = nil)
        Deas::Partial.new(@sinatra_call, name, locals || {}).render
      end
    end

  end

  class Partial < Template

    def initialize(sinatra_call, name, locals = nil)
      options = { :locals => (locals || {}) }
      name = begin
        basename = File.basename(name.to_s)
        name.to_s.sub(/#{basename}\Z/, "_#{basename}")
      end
      super sinatra_call, name, options
    end

  end

end
