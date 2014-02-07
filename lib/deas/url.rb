require 'deas/cgi'

module Deas
  class Url

    attr_reader :name, :path

    def initialize(name, path)
      @name, @path = name, path
    end

    def path_for(*args)
      hashed, ordered = [
        args.last.kind_of?(::Hash) ? args.pop : {},
        args
      ]
      apply_ordered(apply_hashed(@path, hashed), ordered)
    end

    private

    def apply_ordered(path, params)
      params.inject(path){ |p, v| p.sub(/\*+|\:\w+/i, v.to_s) }.gsub(/\/\/+/, '/')
    end

    def apply_hashed(path, params)
      # don't alter the given params
      h = params.dup

      # ignore captures in applying params
      captures = h.delete(:captures) || h.delete('captures') || []
      splat    = h.delete(:splat)    || h.delete('splat')    || []
      anchor   = h.delete(:'#')      || h.delete('#')        || nil

      apply_anchor(apply_extra(apply_named(apply_splat(path, splat), h), h), anchor)
    end

    def apply_splat(path, params)
      params.inject(path){ |p, v| p.sub(/\*+/, v.to_s) }
    end

    def apply_named(path, params)
      params.inject(path) do |p, (k, v)|
        if p.include?(":#{k}")
          params.delete(k)
          p.gsub(":#{k}", v.to_s)
        else
          p
        end
      end
    end

    def apply_extra(path, params)
      params.empty? ? path : "#{path}?#{Deas::Cgi.http_query(params)}"
    end

    def apply_anchor(path, anchor)
      anchor.to_s.empty? ? path : "#{path}##{anchor}"
    end

  end
end
