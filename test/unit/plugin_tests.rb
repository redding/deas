require 'assert'
require 'deas/plugin'

module Deas::Plugin

  class BaseTests < Assert::Context
    TestPlugin = Module.new do
      include Deas::Plugin

      plugin_included{ inc_hook1 }
      plugin_included{ inc_hook2 }
    end

    desc "Deas::Plugin"
    setup do
      @receiver = Class.new do
        def self.inc_hook1;   @hook1_count ||= 0; @hook1_count += 1; end
        def self.hook1_count; @hook1_count ||= 0; end
        def self.inc_hook2;   @hook2_count ||= 0; @hook2_count += 1; end
        def self.hook2_count; @hook2_count ||= 0; end
      end

      @hook1 = proc{ 1 }
      @hook2 = proc{ 2 }

      @plugin = Module.new{ include Deas::Plugin }
    end
    subject{ @plugin }

    should have_imeths :deas_plugin_included_hooks, :deas_plugin_receivers
    should have_imeths :plugin_included

    should "have no plugin_included_hooks by default" do
      assert_empty subject.deas_plugin_included_hooks
    end

    should "have no plugin_receivers by default" do
      assert_empty subject.deas_plugin_receivers
    end

    should "append hooks with #plugin_included" do
      subject.plugin_included(&@hook1)
      subject.plugin_included(&@hook2)

      assert_equal @hook1, subject.deas_plugin_included_hooks.first
      assert_equal @hook2, subject.deas_plugin_included_hooks.last
    end

    should "call the plugin included hooks when mixed in" do
      assert_equal 0, @receiver.hook1_count
      assert_equal 0, @receiver.hook2_count

      @receiver.send(:include, BaseTests::TestPlugin)

      assert_equal 1, @receiver.hook1_count
      assert_equal 1, @receiver.hook2_count
    end

    should "call hooks once when mixed in multiple times" do
      @receiver.send(:include, BaseTests::TestPlugin)

      assert_equal 1, @receiver.hook1_count
      assert_equal 1, @receiver.hook2_count

      @receiver.send(:include, BaseTests::TestPlugin)

      assert_equal 1, @receiver.hook1_count
      assert_equal 1, @receiver.hook2_count
    end

    should "call hooks once when mixed in by a 3rd party" do
      third_party = Module.new do
        def self.included(receiver)
          receiver.send(:include, BaseTests::TestPlugin)
        end
      end
      @receiver.send(:include, third_party)

      assert_equal 1, @receiver.hook1_count
      assert_equal 1, @receiver.hook2_count

      @receiver.send(:include, BaseTests::TestPlugin)

      assert_equal 1, @receiver.hook1_count
      assert_equal 1, @receiver.hook2_count

      @receiver.send(:include, third_party)

      assert_equal 1, @receiver.hook1_count
      assert_equal 1, @receiver.hook2_count
    end

  end

end
