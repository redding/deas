require 'assert'
require 'deas/logging'

module Deas::Logging

  class BaseTests < Assert::Context
    desc "Deas::Logging"
    subject{ Deas::Logging }

    should have_imeths :middleware

  end

  class VerboseLoggingTests < Assert::Context
    desc "Deas::VerboseLogging"
    setup do
      @middleware = Deas::VerboseLogging.new('a rack app goes here')
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "be a kind of Deas::BaseLogging middleware" do
      assert_kind_of Deas::BaseLogging, subject
    end

  end

  class SummaryLoggingTests < Assert::Context
    desc "Deas::SummaryLogging"
    setup do
      @middleware = Deas::SummaryLogging.new('a rack app goes here')
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "be a kind of Deas::BaseLogging middleware" do
      assert_kind_of Deas::BaseLogging, subject
    end

  end

end
