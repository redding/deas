require 'rack'

module Deas

  class Template

    attr_reader :name, :options

    def initialize(sinatra_call, name, options = nil)
      @sinatra_call, @name, @options = sinatra_call, name.to_sym, (options || {})
      @options[:scope] = @sinatra_call.settings.deas_template_scope.new(@sinatra_call)

      (@options.delete(:layout) || @options.delete(:layouts) || []).tap do |l|
        @layouts = l.compact.map(&:to_sym)
      end
    end

    def engine(template_name)
      return 'erb' if @sinatra_call.settings.views.nil?

      views_path = Pathname.new(@options[:views] || @sinatra_call.settings.views)
      template = Dir.glob("#{views_path.join(template_name.to_s)}.*").first.to_s
      File.extname(template)[1..-1] || 'erb'
    end

    # builds render-blocks like:
    #
    #   erb :main_layout do
    #     erb :second_layout do
    #       erb :user_index
    #     end
    #   end

    def render(&block)
      template_names = [ @layouts, @name ].flatten.reverse
      top_render_proc = template_names.inject(block) do |render_proc, name|
        proc{ @sinatra_call.send(engine(name), name, @options.dup, &render_proc) }
      end
      top_render_proc.call
    end

    class Scope

      attr_reader :sinatra_call

      def initialize(sinatra_call)
        @sinatra_call = sinatra_call
      end

      def render(name, options = nil, &block)
        Template.new(@sinatra_call, name, options || {}).render(&block)
      end

      def partial(name, locals = nil, &block)
        Partial.new(@sinatra_call, name, locals || {}).render(&block)
      end

      def escape_html(html)
        Rack::Utils.escape_html(html)
      end
      alias :h :escape_html

      def escape_url(path)
        Rack::Utils.escape_path(path)
      end
      alias :u :escape_url

      def ==(other_scope)
        self.sinatra_call == other_scope.sinatra_call
        self.class.included_modules == other_scope.class.included_modules
      end

    end

    class Partial < Template

      def initialize(sinatra_call, name, locals = nil)
        options = { :locals => (locals || {}) }
        super sinatra_call, name, options
      end

    end

  end

end
