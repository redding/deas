module Deas
  module Plugin

    # use the Plugin mixin to define your own custom plugins you want to mixin
    # on your Deas view handlers.  Define included hooks using `plugin_included`.
    # this allows you to define multiple hooks separately and ensures the hooks
    # will only be called once - even if your plugin is mixed in multiple times.

    def self.included(receiver)
      receiver.class_eval do
        extend ClassMethods

        # install an included hook that first checks if this plugin has
        # already been installed on the reciever.  If it has not been,
        # class eval each callback on the receiver.

        def self.included(plugin_receiver)
          return if self.deas_plugin_receivers.include?(plugin_receiver)

          self.deas_plugin_receivers.push(plugin_receiver)
          self.deas_plugin_included_hooks.each do |hook|
            plugin_receiver.class_eval(&hook)
          end
        end

      end
    end

    module ClassMethods

      def deas_plugin_receivers; @plugin_receivers ||= []; end
      def deas_plugin_included_hooks; @plugin_included_hooks ||= []; end
      def plugin_included(&hook); self.deas_plugin_included_hooks << hook; end

    end

  end
end
