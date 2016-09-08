require 'assert'
require 'deas/server_data'

class Deas::ServerData

  class UnitTests < Assert::Context
    desc "Deas::ServerData"
    setup do
      @error_procs     = Factory.integer(3).times.map{ proc{} }
      @logger          = Factory.string
      @router          = Factory.string
      @template_source = Factory.string

      @server_data = Deas::ServerData.new({
        :error_procs     => @error_procs,
        :logger          => @logger,
        :router          => @router,
        :template_source => @template_source
      })
    end
    subject{ @server_data }

    should have_readers :error_procs, :logger, :router, :template_source

    should "know its attributes" do
      assert_equal @error_procs,     subject.error_procs
      assert_equal @logger,          subject.logger
      assert_equal @router,          subject.router
      assert_equal @template_source, subject.template_source
    end

    should "default its attributes when they aren't provided" do
      server_data = Deas::ServerData.new({})

      assert_equal [], server_data.error_procs
      assert_nil server_data.logger
      assert_nil server_data.router
      assert_nil server_data.template_source
    end

    should "know if it is equal to another server data" do
      server_data = Deas::ServerData.new({
        :error_procs     => @error_procs,
        :logger          => @logger,
        :router          => @router,
        :template_source => @template_source
      })
      assert_equal server_data, subject

      server_data = Deas::ServerData.new({})
      assert_not_equal server_data, subject
    end

  end

end
