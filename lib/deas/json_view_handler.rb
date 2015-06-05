require 'deas/view_handler'

module Deas

  module JsonViewHandler

    def self.included(klass)
      klass.class_eval do
        include Deas::ViewHandler
        include InstanceMethods
      end
    end

    module InstanceMethods

      def initialize(*args)
        super(*args)
        content_type :json
      end

      private

      # Some http clients will error when trying to parse an empty body when the
      # content type is 'json'.  This will default the body to a string that
      # can be parsed to an empty json object
      def halt(status, headers = {}, body = '{}')
        super(status, headers, body)
      end

    end

  end

end
