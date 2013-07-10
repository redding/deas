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
      splat = params[:splat] || params['splat'] || '*'
      params.inject(path){ |s, (k, v)| s.gsub(":#{k}", v) }.gsub("*", splat)
    end

    def apply_ordered_params(path, params)
      params.inject(path){ |s, p| s.sub(/\*+|\:\w+/i, p) }
    end

  end
end
