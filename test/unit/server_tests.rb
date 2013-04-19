require 'assert'
require 'deas/server'

class Deas::Server

  class BaseTests < Assert::Context
    desc "Deas::Server"
    setup do
      @old_configuration = Deas::Server.configuration.dup
      new_configuration = Deas::Server::Configuration.new
      Deas::Server.instance.tap do |s|
        s.instance_variable_set("@configuration", new_configuration)
      end
    end
    teardown do
      Deas::Server.instance.tap do |s|
        s.instance_variable_set("@configuration", @old_configuration)
      end
    end
    subject{ Deas::Server }

    should have_instance_methods :configuration, :init

    should "be a singleton" do
      assert_includes Singleton, subject.included_modules
    end

    should "allow setting it's configuration options" do
      config = subject.configuration

      subject.env 'staging'
      assert_equal 'staging', config.env

      subject.root '/path/to/root'
      assert_equal '/path/to/root', config.root.to_s

      subject.public_folder '/path/to/public'
      assert_equal '/path/to/public', config.public_folder.to_s

      subject.views_folder '/path/to/views'
      assert_equal '/path/to/views', config.views_folder.to_s

      subject.dump_errors true
      assert_equal true, config.dump_errors

      subject.method_override false
      assert_equal false, config.method_override

      subject.sessions false
      assert_equal false, config.sessions

      subject.static_files false
      assert_equal false, config.static_files

      stdout_logger = Logger.new(STDOUT)
      subject.logger stdout_logger
      assert_equal stdout_logger, config.logger

      init_proc = proc{ }
      subject.init(&init_proc)
      assert_equal init_proc, config.init_proc
    end

  end

  class ConfigurationTests < BaseTests
    desc "Configuration"
    setup do
      @configuration = Deas::Server.configuration
    end
    subject{ @configuration }

    should have_instance_methods :env, :root, :app_file, :public_folder,
      :views_folder, :dump_errors, :method_override, :sessions, :static_files,
      :init_proc, :logger

    should "default the env to 'development'" do
      assert_equal 'development', subject.env
    end

    should "default the root to the routes file's folder" do
      expected_root = File.expand_path('..', Deas.config.routes_file)
      assert_equal expected_root, subject.root.to_s
    end

    should "default the app file to the routes file" do
      assert_equal Deas.config.routes_file.to_s, subject.app_file.to_s
    end

    should "default the public folder based on the root" do
      expected_root = File.expand_path('..', Deas.config.routes_file)
      expected_public_folder = File.join(expected_root, 'public')
      assert_equal expected_public_folder, subject.public_folder.to_s
    end

    should "default the views folder based on the root" do
      expected_root = File.expand_path('..', Deas.config.routes_file)
      expected_views_folder = File.join(expected_root, 'views')
      assert_equal expected_views_folder, subject.views_folder.to_s
    end

    should "default the Sinatra flags" do
      assert_equal false, subject.dump_errors
      assert_equal true,  subject.method_override
      assert_equal true,  subject.sessions
      assert_equal true,  subject.static_files
    end

    should "default the logger to a NullLogger" do
      assert_instance_of Deas::NullLogger, subject.logger
    end

  end

end
