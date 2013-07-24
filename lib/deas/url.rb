module Deas
  class Url

    attr_reader :name, :path

    def initialize(name, path)
      @name, @path = name, path
    end

    def path_for(*args)
      named, ordered = [
        args.last.kind_of?(::Hash) ? args.pop : {},
        args
      ]
      apply_ordered_params(apply_named_params(@path, named), ordered)
    end

    private

    def apply_named_params(path, params)
      # ignore captures in applying params
      captures   = params.delete(:captures) || params.delete('captures') || []
      splat      = params.delete(:splat)    || params.delete('splat')    || []
      splat_path = splat.inject(path){ |p, v| p.sub(/\*+/, v.to_s) }
      params.inject(splat_path){ |p, (k, v)| p.gsub(":#{k}", v.to_s) }
    end

    def apply_ordered_params(path, params)
      params.inject(path){ |p, v| p.sub(/\*+|\:\w+/i, v.to_s) }.gsub(/\/\/+/, '/')
    end

  end
end
