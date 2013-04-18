require 'assert'
require 'deas'

module Deas

  class BaseTests < Assert::Context
    desc "Deas"
    subject{ Deas }

    should have_instance_methods :config, :configure, :init, :app

  end

  class ConfigTests < BaseTests
    desc "Deas::Config"
    subject{ Deas::Config }

    should have_instance_methods :routes_file
  end

end
