require 'deas/view_handler'

module Deas

  module RedirectHandler

    def self.new(path = nil, &block)
      handler_class = Class.new do
        include Deas::ViewHandler
        include InstanceMethods
        extend ClassMethods
      end
      handler_class.redirect_path = path ? proc{ path } : block
      handler_class
    end

    module InstanceMethods

      def run!
        path = self.instance_eval(&self.class.redirect_path)
        redirect path
      end

    end

    module ClassMethods

      attr_accessor :redirect_path

    end

  end

end
