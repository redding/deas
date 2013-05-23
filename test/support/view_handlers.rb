require 'deas/view_handler'

class TestViewHandler
  include Deas::ViewHandler

end

class RenderViewHandler
  include Deas::ViewHandler

  def run!
    render "my_template", :some => :option
  end
end

class FlagViewHandler
  include Deas::ViewHandler
  before{ @before_hook_called = true }
  after{  @after_hook_called  = true }
  layout 'web'

  attr_reader :before_init_called, :init_bang_called, :after_init_called,
    :before_run_called, :run_bang_called, :after_run_called,
    :before_hook_called, :after_hook_called, :second_before_init_called

  before_init do
    @before_init_called = true
  end
  before_init do
    @second_before_init_called = true
  end

  def init!
    @init_bang_called = true
  end

  after_init do
    @after_init_called = true
  end

  before_run do
    @before_run_called = true
  end

  def run!
    @run_bang_called = true
  end

  after_run do
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

class ContentTypeViewHandler
  include Deas::ViewHandler

  def run!
    content_type 'text/plain', :charset => 'latin1'
  end

end
