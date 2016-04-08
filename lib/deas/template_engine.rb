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
      paths = Dir.glob(self.source_path.join("#{template_name}*"))
      if paths.size > 1
        raise ArgumentError, "#{template_name.inspect} matches more than one " \
                             "file, consider using a more specific template name"
      end
      if paths.size < 1
        raise ArgumentError, "a template file named #{template_name.inspect} " \
                             "does not exist"
      end
      File.read(paths.first)
    end

    def partial(template_name, locals, &content)
      render(template_name, nil, locals)
    end

    def compile(template_name, compiled_content)
      compiled_content # no-op, pass-thru - just return the given content
    end

  end

end
