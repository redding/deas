require 'rack/utils'
require 'pathname'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'

module Deas

  class Runner

    DEFAULT_MIME_TYPE = 'application/octet-stream'.freeze
    DEFAULT_CHARSET   = 'utf-8'.freeze

    def self.body_value(value)
      # http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body
      # "The Body must respond to each and must only yield String values"
      # String#each is a thing in 1.8.7, so account for it here
      return nil if value.to_s.empty?
      !value.respond_to?(:each) || value.kind_of?(String) ? [*value.to_s] : value
    end

    attr_reader :handler_class, :handler
    attr_reader :request, :route_path, :params
    attr_reader :logger, :router, :template_source

    def initialize(handler_class, args = nil)
      @handler_class = handler_class
      @status, @body = nil, nil
      @headers = Rack::Utils::HeaderHash.new.merge(@handler_class.default_headers)
      @handler = @handler_class.new(self)

      args ||= {}
      @request         = args[:request]
      @route_path      = args[:route_path].to_s
      @params          = args[:params]          || {}
      @logger          = args[:logger]          || Deas::NullLogger.new
      @router          = args[:router]          || Deas::Router.new
      @template_source = args[:template_source] || Deas::NullTemplateSource.new
    end

    def splat
      @splat ||= parse_splat_value
    end

    def run
      raise NotImplementedError
    end

    def to_rack
      [ self.status || @handler_class.default_status,
        self.headers.to_hash,
        self.body   || @handler_class.default_body
      ]
    end

    def status(value = nil)
      @status = value if !value.nil?
      @status
    end

    def headers(value = nil)
      @headers.merge!(value) if !value.nil?
      @headers
    end

    def body(value = nil)
      if !value.nil?
        @body = self.class.body_value(value)
      end
      @body
    end

    def content_type(extname, params = nil)
      self.headers['Content-Type'] = get_content_type(extname, params)
    end

    def set_cookie(name, value, opts = nil)
      Rack::Utils.set_cookie_header!(
        self.headers,
        name,
        (opts || {}).merge(:value => value)
      )
    end

    def halt(*args)
      self.status(args.shift)  if args.first.instance_of?(::Fixnum)
      self.headers(args.shift) if args.first.kind_of?(::Hash)
      self.body(args.shift)    if !args.first.to_s.empty?
      throw :halt
    end

    def redirect(location, *halt_args)
      self.status(302)
      self.headers['Location'] = get_absolute_url(location)
      halt(*halt_args)
    end

    def send_file(file_path, opts = nil)
      path_name = Pathname.new(file_path)
      self.halt(404, []) if !path_name.exist?

      env   = self.request.env
      mtime = path_name.mtime.httpdate.to_s
      self.halt(304, []) if env['HTTP_IF_MODIFIED_SINCE'] == mtime
      self.headers['Last-Modified'] ||= mtime

      self.headers['Content-Type'] ||= get_content_type(path_name.extname)

      opts ||= {}
      disposition = opts[:disposition]
      filename    = opts[:filename]
      disposition ||= 'attachment' if !filename.nil?
      filename    ||= path_name.basename
      if !disposition.nil?
        self.headers['Content-Disposition'] ||= "#{disposition};filename=\"#{filename}\""
      end

      sfb = SendFileBody.new(env, path_name)
      self.body(sfb)
      self.headers['Content-Length'] ||= sfb.size.to_s
      self.headers['Content-Range']  ||= sfb.content_range if sfb.partial?
      self.status(sfb.partial? ? 206 : 200)

      self.halt # be consistent with halts above - `send_file` always halts
    end

    def render(template_name, locals = nil)
      source_render(self.template_source, template_name, locals)
    end

    def source_render(source, template_name, locals = nil)
      self.headers['Content-Type'] ||= get_content_type(
        File.extname(template_name),
        'charset' => DEFAULT_CHARSET
      )
      self.body(source.render(template_name, self.handler, locals || {}))
    end

    def partial(template_name, locals = nil)
      source_partial(self.template_source, template_name, locals)
    end

    def source_partial(source, template_name, locals = nil)
      source.partial(template_name, locals || {})
    end

    private

    def get_content_type(extname, params = nil)
      [ Rack::Mime.mime_type(extname, DEFAULT_MIME_TYPE),
        params ? params.map{ |k,v| "#{k}=#{v}" }.join(',') : nil
      ].compact.join(';')
    end

    def get_absolute_url(url)
      return url if url =~ /\A[A-z][A-z0-9\+\.\-]*:/
      File.join("#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}", url)
    end

    def parse_splat_value
      return nil if request.nil? || (path_info = request.env['PATH_INFO']).nil?

      regex = splat_value_parse_regex
      match = regex.match(path_info)
      if match.nil?
        raise SplatParseError, "could not parse the splat value: " \
                               "the PATH_INFO, `#{path_info.inspect}`, " \
                               "doesn't match " \
                               "the route, `#{self.route_path.inspect}`, " \
                               "using the route regex, `#{regex.inspect}`"
      end
      match.captures.first
    end

    SplatParseError = Class.new(RuntimeError)

    def splat_value_parse_regex
      # `sub` should suffice as only a single trailing splat is allowed. Replace
      # any splat with a capture placholder so we can extract the splat value.
      /^#{route_path_with_regex_placeholders.sub('*', '(.+?)')}$/
    end

    def route_path_with_regex_placeholders
      # Replace param values with regex placeholders b/c we don't care what
      # the values are just that "a param value goes here".  Use gsub in the odd
      # case a placeholder is used more than once in a route.  This is to help
      # ensure matching and capturing splats even on nonsense paths.
      sorted_param_names.inject(self.route_path) do |path, name|
        path.gsub(":#{name}", '.+?')
      end
    end

    def sorted_param_names
      # Sort longer key names first so they will be processed first.  This
      # ensures that shorter param names that compose longer param names won't
      # be subbed in the longer param name's place.
      self.params.keys.sort{ |a, b| b.size <=> a.size }
    end

    class NormalizedParams

      attr_reader :value

      def initialize(value)
        @value = if value.is_a?(::Array)
          value.map{ |i| self.class.new(i).value }
        elsif self.hash_type?(value)
          value.inject({}){ |h, (k, v)| h[k.to_s] = self.class.new(v).value; h }
        elsif self.file_type?(value)
          value
        else
          value.to_s
        end
      end

      def file_type?(value)
        raise NotImplementedError
      end

      def hash_type?(value)
        # this supports older Rack versions (that don't have
        # Utils#params_hash_type?)
        ( Rack::Utils.respond_to?('params_hash_type?') &&
          Rack::Utils.params_hash_type?(value)
        ) || value.kind_of?(::Hash)
      end

    end

    class SendFileBody

      # this class borrows from the body range handling in Rack::File.

      CHUNK_SIZE = (8*1024).freeze # 8k

      attr_reader :path_name, :size, :content_range

      def initialize(env, path_name)
        @path_name = path_name

        file_size = @path_name.size? || Rack::Utils.bytesize(path_name.read)
        ranges = byte_ranges(env, file_size)
        if ranges.nil? || ranges.empty? || ranges.length > 1
          # No ranges or multiple ranges are not supported
          @range         = 0..file_size-1
          @content_range = nil
        else
          # single range
          @range         = ranges[0]
          @content_range = "bytes #{@range.begin}-#{@range.end}/#{file_size}"
        end

        @size = self.range_end - self.range_begin + 1
      end

      def partial?
        !@content_range.nil?
      end

      def range_begin; @range.begin; end
      def range_end;   @range.end;   end

      def each
        @path_name.open("rb") do |io|
          io.seek(@range.begin)
          remaining_len = self.size
          while remaining_len > 0
            part = io.read([CHUNK_SIZE, remaining_len].min)
            break if part.nil?

            remaining_len -= part.length
            yield part
          end
        end
      end

      def inspect
        "#<#{self.class}:#{'0x0%x' % (self.object_id << 1)} " \
          "path=#{self.path_name} " \
          "range_begin=#{self.range_begin} range_end=#{self.range_end}>"
      end

      def ==(other_body)
        self.path_name.to_s == other_body.path_name.to_s &&
        self.range_begin    == other_body.range_begin    &&
        self.range_end      == other_body.range_end
      end

      private

      def byte_ranges(env, file_size)
        if Rack::Utils.respond_to?('byte_ranges')
          Rack::Utils.byte_ranges(env, file_size)
        else
          nil
        end
      end

    end

  end

end
