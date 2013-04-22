require 'deas/view_handler'

class TestViewHandler
  include Deas::ViewHandler

end

class FlagViewHandler
  include Deas::ViewHandler
  before{ @before_hook_called = true }
  after{  @after_hook_called  = true }

  attr_reader :before_init_called, :init_bang_called, :after_init_called,
    :before_run_called, :run_bang_called, :after_run_called,
    :before_hook_called, :after_hook_called

  def before_init
    @before_init_called = true
  end

  def init!
    @init_bang_called = true
  end

  def after_init
    @after_init_called = true
  end

  def before_run
    @before_run_called = true
  end

  def run!
    @run_bang_called = true
  end

  def after_run
    @after_run_called = true
  end

end

class HaltViewHandler
  include Deas::ViewHandler

  def run!
    halt_args = [ params['code'], params['headers'], params['body'] ].compact
    halt(*halt_args)
  end

end
