require 'deas/logger'
require 'deas/template_engine'

module Deas

  class TemplateSource

    DISALLOWED_ENGINE_EXTS = [ 'rb' ]

    DisallowedEngineExtError = Class.new(ArgumentError)

    attr_reader :path, :engines

    def initialize(path, logger = nil)
      @path = path.to_s
      @default_engine_opts = {
        'source_path'             => @path,
        'logger'                  => logger || Deas::NullLogger.new,
        'default_template_source' => self
      }
      @engines = Hash.new{ |h, k| Deas::NullTemplateEngine.new(@default_engine_opts) }
      @ext_lists = Hash.new do |hash, template_name|
        # An ext list is an array of non-template-name extensions that have engines
        # configured.  The first ext in the list is the most precedent. Its engine
        # is used to do the initial render from the named template file. Any
        # further exts are used to compile rendered content from upsteam engines.
        hash[template_name] = parse_ext_list(template_name)
      end
    end

    def engine(input_ext, engine_class, registered_opts = nil)
      if DISALLOWED_ENGINE_EXTS.include?(input_ext)
        raise DisallowedEngineExtError, "`#{input_ext}` is disallowed as an"\
                                        " engine extension."
      end
      engine_opts = @default_engine_opts.merge(registered_opts || {})
      engine_opts['ext'] = input_ext.to_s
      @engines[input_ext.to_s] = engine_class.new(engine_opts)
    end

    def engine_for?(ext)
      @engines.keys.include?(ext)
    end

    def render(template_name, view_handler, locals, &content)
      [ view_handler.layouts,
        template_name
      ].flatten.reverse.inject(content) do |render_proc, name|
        proc do
          compile(name) do |engine|
            engine.render(name, view_handler, locals, &render_proc)
          end
        end
      end.call
    end

    def partial(template_name, locals, &content)
      compile(template_name) do |engine|
        engine.partial(template_name, locals, &content)
      end
    end

    private

    def compile(name)
      @ext_lists[name].drop(1).inject(yield @engines[@ext_lists[name].first]) do |c, e|
        @engines[e].compile(name, c)
      end
    end

    def parse_ext_list(template_name)
      no_ext_path = "#{File.join(@path, template_name.to_s)}."
      path = Dir.glob("#{no_ext_path}*").first || ''
      path.sub(no_ext_path, '').split('.').reverse.reject do |ext|
        !self.engine_for?(ext)
      end
    end

  end

  class NullTemplateSource < TemplateSource

    def initialize(root = nil)
      super(root || '')
    end

  end

end
