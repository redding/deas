require 'deas/logger'
require 'deas/template_engine'

module Deas

  class TemplateSource

    attr_reader :path, :engines

    def initialize(path, logger = nil)
      @path = path.to_s
      @default_engine_opts = {
        'source_path'             => @path,
        'logger'                  => logger || Deas::NullLogger.new,
        'default_template_source' => self
      }
      @engines = Hash.new do |hash, ext|
        # cache null template exts so we don't repeatedly call this block for
        # known null template exts
        hash[ext.to_s] = Deas::NullTemplateEngine.new(@default_engine_opts)
      end
      @engine_exts = []
      @ext_lists = Hash.new do |hash, template_name|
        # An ext list is an array of non-template-name extensions that have engines
        # configured.  The first ext in the list is the most precedent. Its engine
        # is used to do the initial render from the named template file. Any
        # further exts are used to compile rendered content from upsteam engines.
        hash[template_name] = parse_ext_list(template_name)
      end
    end

    def engine(input_ext, engine_class, registered_opts = nil)
      @engine_exts << input_ext.to_s

      engine_opts = @default_engine_opts.merge(registered_opts || {})
      engine_opts['ext'] = input_ext.to_s
      @engines[input_ext.to_s] = engine_class.new(engine_opts)
    end

    def engine_for?(ext)
      @engine_exts.include?(ext.to_s)
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
      paths = Dir.glob(File.join(@path, "#{template_name}*"))
      if paths.size > 1
        raise ArgumentError, "#{template_name.inspect} matches more than one " \
                             "file, consider using a more specific template name"
      end
      get_ext_list(paths.first.to_s)
    end

    def get_ext_list(path)
      # get the base name of the path (file name plus extensions).  Split on the
      # periods and drop the first value (the file name).  reverse the list b/c
      # we process exts right-to-left.  reject any unnecessary exts.
      File.basename(path).split('.').drop(1).reverse.reject.each_with_index do |e, i|
        # keep the first ext (for initial render from source) and any registered
        # exts.  remove any non-first non-registered exts so you don't have the
        # overhead of running through the null engine for each.
        i != 0 && !self.engine_for?(e)
      end
    end

  end

  class NullTemplateSource < TemplateSource

    def initialize(root = nil)
      super(root || '')
    end

  end

end
