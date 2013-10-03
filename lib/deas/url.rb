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
      hash = params.dup

      # ignore captures in applying params
      captures = hash.delete(:captures) || hash.delete('captures') || []
      splat    = hash.delete(:splat)    || hash.delete('splat')    || []

      apply_extra(apply_named(apply_splat(@path, splat), hash), hash)
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

  end
end
