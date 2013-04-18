require 'assert'
require 'deas/server'

class Deas::Server

  class BaseTests < Assert::Context
    desc "Deas::Server"
    subject{ Deas::Server }

    should have_instance_methods :configuration, :init

    should "be a singleton" do
      assert_includes Singleton, subject.included_modules
    end

    should "allow setting it's configuration options" do
      init_proc = proc{ }
      subject.init(&init_proc)
      assert_equal init_proc, subject.configuration.init_proc
    end

  end

  class ConfigurationTests < BaseTests
    desc "Configuration"
    setup do
      @configuration = Deas::Server.configuration
    end
    subject{ @configuration }

    should have_instance_methods :init_proc

  end

end
