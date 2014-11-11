require 'deas/url'
require 'deas/view_handler'

module Deas

  class RedirectProxy

    attr_reader :handler_class_name, :handler_class

    def initialize(path = nil, &block)
      @handler_class = Class.new do
        include Deas::ViewHandler

        def self.redirect_path; @redirect_path; end
        def self.redirect_path=(value)
          @redirect_path = value
        end

        def self.name; 'Deas::RedirectHandler'; end

        attr_reader :redirect_path

        def init!
          @redirect_path = self.instance_eval(&self.class.redirect_path)
        end

        def run!
          redirect @redirect_path
        end

      end

      @handler_class.redirect_path = if path.nil?
        block
      elsif path.kind_of?(Deas::Url)
        proc{ path.path_for(params) }
      else
        proc{ path }
      end
      @handler_class_name = @handler_class.name
    end

    def validate!; end

  end

end
