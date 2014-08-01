require 'assert'
require 'test/support/fake_sinatra_call'
require 'deas/logging'

module Deas::Logging

  class UnitTests < Assert::Context
    desc "Deas::Logging"
    setup do
      @app = FakeSinatraCall.new
    end
    subject{ Deas::Logging }

    should have_imeths :middleware

  end

  class VerboseLoggingTests < UnitTests
    desc "Deas::VerboseLogging"
    setup do
      @middleware = Deas::VerboseLogging.new(@app)
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "be a kind of Deas::BaseLogging middleware" do
      assert_kind_of Deas::BaseLogging, subject
    end

  end

  class SummaryLoggingTests < UnitTests
    desc "Deas::SummaryLogging"
    setup do
      @middleware = Deas::SummaryLogging.new(@app)
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "be a kind of Deas::BaseLogging middleware" do
      assert_kind_of Deas::BaseLogging, subject
    end

  end

  class SummaryLineTests < UnitTests
    desc "Deas::SummaryLine"
    subject{ Deas::SummaryLine }

    should "output its attributes in a specific order" do
      assert_equal %w{time status method path handler params redir}, subject.keys
    end

    should "output its attributes in a single line" do
      line_attrs = {
        'time'    => 't',
        'status'  => 's',
        'method'  => 'm',
        'path'    => 'pth',
        'handler' => 'h',
        'params'  => 'p',
        'redir'   => 'r'
      }
      exp_line = "time=\"t\" "\
                 "status=\"s\" "\
                 "method=\"m\" "\
                 "path=\"pth\" "\
                 "handler=\"h\" "\
                 "params=\"p\" "\
                 "redir=\"r\""
      assert_equal exp_line, subject.new(line_attrs)
    end

    should "only output keys if data exists for them" do
      line_attrs = {
        'status'  => 's',
        'path'    => 'pth',
        'handler' => 'h',
        'params'  => 'p'
      }
      exp_line = "status=\"s\" "\
                 "path=\"pth\" "\
                 "handler=\"h\" "\
                 "params=\"p\""
      assert_equal exp_line, subject.new(line_attrs)
    end

  end

end
