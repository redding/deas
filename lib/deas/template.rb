module Deas

  class Template
    attr_reader :name, :options

    def initialize(sinatra_call, name, options = nil)
      @options = options || {}
      @options[:scope] = RenderScope.new(sinatra_call)

      @sinatra_call = sinatra_call
      @name         = name.to_sym
      (@options.delete(:layout) || @options.delete(:layouts) || []).tap do |l|
        @layouts = l.compact.map(&:to_sym)
      end
    end

    # builds Sinatra render-blocks like:
    #
    #   erb :main_layout do
    #     erb :second_layout do
    #       erb :user_index
    #     end
    #   end
    #
    def render(&block)
      template_names = [ @layouts, @name ].flatten.reverse
      top_render_proc = template_names.inject(block) do |render_proc, name|
        proc{ @sinatra_call.erb(name, @options, &render_proc) }
      end
      top_render_proc.call
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
