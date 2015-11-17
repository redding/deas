require 'deas/template_source'
require 'deas/view_handler'

class EmptyViewHandler
  include Deas::ViewHandler

end

class TestRunnerViewHandler
  include Deas::ViewHandler

  attr_reader :before_called, :init_called, :run_called
  attr_accessor :custom_value

  before{ @before_called = true }

  def init!; @init_called = true; end
  def run!;  @run_called  = true; end

end

class DeasRunnerViewHandler
  include Deas::ViewHandler

  attr_accessor :halt_in_before, :halt_in_after
  attr_reader :before_called, :after_called
  attr_reader :init_bang_called, :run_bang_called

  layout 'web'

  before{ halt if @halt_in_before; @before_called = true }
  after{  halt if @halt_in_after;  @after_called  = true }

  def init!
    @init_bang_called = true
  end

  def run!
    @run_bang_called = true
    body Factory.integer(3).times.map{ Factory.text }
  end

end
