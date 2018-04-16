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
      s = h.delete(:splat)    || h.delete('splat')    || nil
      a = h.delete(:'#')      || h.delete('#')        || nil

      # ignore captures when setting params
      # remove duplicate forward slashes
      set_anchor(set_extra(set_named(set_splat(@path, s), h).gsub(/\/\/+/, '/'), h), a)
    end

    private

    def set_splat(path, value)
      path.sub(/\*+/, value.to_s)
    end

    def set_named(path, params)
      # Process longer param names first. This ensures that shorter names that
      # compose longer names won't be set as a part of the longer name.
      params.keys.sort{ |a, b| b.to_s.size <=> a.to_s.size }.inject(path) do |p, name|
        if p.include?(":#{name}")
          if (v = params[name].to_s).empty?
            raise EmptyNamedValueError , "an empty value, " \
                                         "`#{params[name].inspect}`, " \
                                         "was given for the " \
                                         "`#{name.inspect}` url param"
          end
          params.delete(name)
          p.gsub(":#{name}", v)
        else
          p
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

    NonHashParamsError   = Class.new(ArgumentError)
    EmptyNamedValueError = Class.new(ArgumentError)

  end

end
