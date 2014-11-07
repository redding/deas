require 'deas/template_engine'

module Deas

  class TemplateSource

    DISALLOWED_ENGINE_EXTS = [ 'rb' ]

    DisallowedEngineExtError = Class.new(ArgumentError)

    attr_reader :path, :engines

    def initialize(path)
      @path = path.to_s
      @default_opts = { 'source_path' => @path }
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

    def render(template_path, view_handler, locals)
      engine = @engines[get_template_ext(template_path)]
      engine.render(template_path, view_handler, locals)
    end

    private

    def get_template_ext(template_path)
      files = Dir.glob("#{File.join(@path, template_path.to_s)}.*")
      files = files.reject{ |p| !@engines.keys.include?(parse_ext(p)) }
      parse_ext(files.first.to_s || '')
    end

    def parse_ext(template_path)
      File.extname(template_path)[1..-1]
    end

  end

  class NullTemplateSource < TemplateSource

    def initialize
      super('')
    end

  end

end
