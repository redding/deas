require 'assert'
require 'deas/server_data'

class Deas::ServerData

  class UnitTests < Assert::Context
    desc "Deas::ServerData"
    setup do
      @error_procs            = Factory.integer(3).times.map{ proc{ Factory.string } }
      @before_route_run_procs = Factory.integer(3).times.map{ proc{ Factory.string } }
      @after_route_run_procs  = Factory.integer(3).times.map{ proc{ Factory.string } }
      @logger                 = Factory.string
      @router                 = Factory.string
      @template_source        = Factory.string

      @server_data = Deas::ServerData.new({
        :error_procs            => @error_procs,
        :before_route_run_procs => @before_route_run_procs,
        :after_route_run_procs  => @after_route_run_procs,
        :logger                 => @logger,
        :router                 => @router,
        :template_source        => @template_source
      })
    end
    subject{ @server_data }

    should have_readers :error_procs, :before_route_run_procs, :after_route_run_procs
    should have_readers :logger, :router, :template_source

    should "know its attributes" do
      assert_equal @error_procs,            subject.error_procs
      assert_equal @before_route_run_procs, subject.before_route_run_procs
      assert_equal @after_route_run_procs,  subject.after_route_run_procs
      assert_equal @logger,                 subject.logger
      assert_equal @router,                 subject.router
      assert_equal @template_source,        subject.template_source
    end

    should "default its attributes when they aren't provided" do
      server_data = Deas::ServerData.new({})

      assert_equal [], server_data.error_procs
      assert_equal [], server_data.before_route_run_procs
      assert_equal [], server_data.after_route_run_procs
      assert_nil server_data.logger
      assert_nil server_data.router
      assert_nil server_data.template_source
    end

    should "know if it is equal to another server data" do
      server_data = Deas::ServerData.new({
        :error_procs            => @error_procs,
        :before_route_run_procs => @before_route_run_procs,
        :after_route_run_procs  => @after_route_run_procs,
        :logger                 => @logger,
        :router                 => @router,
        :template_source        => @template_source
      })
      assert_equal server_data, subject

      server_data = Deas::ServerData.new({})
      assert_not_equal server_data, subject
    end

  end

end
