module Deas
  class Url

    attr_reader :name, :path

    def initialize(name, path)
      @name, @path = name, path
    end

  end
end
