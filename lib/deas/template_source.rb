require 'deas/logger'
require 'deas/template_engine'

module Deas

  class TemplateSource

    DISALLOWED_ENGINE_EXTS = [ 'rb' ]

    DisallowedEngineExtError = Class.new(ArgumentError)

    attr_reader :path, :engines

    def initialize(path, logger = nil)
      @path = path.to_s
      @default_opts = {
        'source_path' => @path,
        'logger'      => logger || Deas::NullLogger.new
      }
      @engines = Hash.new{ |h,k| Deas::NullTemplateEngine.new(@default_opts) }
    end

    def engine(input_ext, engine_class, registered_opts = nil)
      if DISALLOWED_ENGINE_EXTS.include?(input_ext)
        raise DisallowedEngineExtError, "`#{input_ext}` is disallowed as an"\
                                        " engine extension."
      end
      engine_opts = @default_opts.merge(registered_opts || {})
      @engines[input_ext.to_s] = engine_class.new(engine_opts)
    end

    def render(template_name, view_handler, locals)
      get_engine(template_name).render(template_name, view_handler, locals)
    end

    def partial(template_name, locals)
      get_engine(template_name).partial(template_name, locals)
    end

    def capture_partial(template_name, locals, &content)
      get_engine(template_name).capture_partial(template_name, locals, &content)
    end

    private

    def get_engine(template_name)
      @engines[get_template_ext(template_name)]
    end

    def get_template_ext(template_name)
      files = Dir.glob("#{File.join(@path, template_name.to_s)}.*")
      files = files.reject{ |p| !@engines.keys.include?(parse_ext(p)) }
      parse_ext(files.first.to_s || '')
    end

    def parse_ext(template_name)
      File.extname(template_name)[1..-1]
    end

  end

  class NullTemplateSource < TemplateSource

    def initialize
      super('')
    end

  end

end
