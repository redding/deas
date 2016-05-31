module Deas

  class Url

    def self.http_query(hash, &escape_value_proc)
      escape_value_proc ||= proc{ |v| v.to_s }
      hash.map do |(key, value)|
        "#{key}=#{escape_value_proc.call(value)}"
      end.sort.join('&')
    end

    attr_reader :name, :path
    attr_reader :escape_query_value_proc

    def initialize(name, path, options = nil)
      options ||= {}
      @name, @path = name, path
      @escape_query_value_proc = options[:escape_query_value]
    end

    def path_for(params = {})
      raise NonHashParamsError if !params.kind_of?(::Hash)

      h = params.dup # don't alter the given params
      c = h.delete(:captures) || h.delete('captures') || []
      s = h.delete(:splat)    || h.delete('splat')    || []
      a = h.delete(:'#')      || h.delete('#')        || nil

      # ignore captures when setting params
      # remove duplicate forward slashes
      set_anchor(set_extra(set_named(set_splat(@path, s), h), h), a).gsub(/\/\/+/, '/')
    end

    private

    def set_splat(path, params)
      params.inject(path) do |path_string, value|
        path_string.sub(/\*+/, value.to_s)
      end
    end

    def set_named(path, params)
      params.inject(path) do |path_string, (name, value)|
        if path_string.include?(":#{name}")
          params.delete(name)
          path_string.gsub(":#{name}", value.to_s)
        else
          path_string
        end
      end
    end

    def set_extra(path, params)
      return path if params.empty?
      query_string = Deas::Url.http_query(params, &self.escape_query_value_proc)
      "#{path}?#{query_string}"
    end

    def set_anchor(path, anchor)
      anchor.to_s.empty? ? path : "#{path}##{anchor}"
    end

    NonHashParamsError = Class.new(ArgumentError)

  end

end
