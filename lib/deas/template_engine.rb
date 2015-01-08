require 'pathname'
require 'deas/logger'

module Deas

  class TemplateEngine

    attr_reader :source_path, :logger, :opts

    def initialize(opts = nil)
      @opts = opts || {}
      @source_path = Pathname.new(@opts['source_path'].to_s)
      @logger = @opts['logger'] || Deas::NullLogger.new
    end

    def render(template_name, view_handler, locals, &content)
      raise NotImplementedError
    end

    def partial(template_name, locals, &content)
      raise NotImplementedError
    end

    def compile(template_name, compiled_content)
      raise NotImplementedError
    end

  end

  class NullTemplateEngine < TemplateEngine

    def render(template_name, view_handler, locals, &content)
      template_file = self.source_path.join(template_name).to_s
      unless File.exists?(template_file)
        raise ArgumentError, "template file `#{template_file}` does not exist"
      end
      File.read(template_file)
    end

    def partial(template_name, locals, &content)
      render(template_name, nil, locals)
    end

    def compile(template_name, compiled_content)
      compiled_content  # no-op, pass-thru - just return the given content
    end

  end

end
